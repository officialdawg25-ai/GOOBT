import {describe,it,expect} from 'vitest';
import {verifyPaystackWebhookSignature} from '../../../supabase/functions/_shared/payments/paystack.ts';

const encoder=new TextEncoder();

function toHex(bytes:Uint8Array):string {
  return Array.from(bytes,value=>value.toString(16).padStart(2,'0')).join('');
}

async function sign(secret:string,message:Uint8Array):Promise<string> {
  const key=await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-512'},false,['sign']);
  const messageCopy=new Uint8Array(message.byteLength);messageCopy.set(message);const messageBuffer:ArrayBuffer=messageCopy.buffer;return toHex(new Uint8Array(await crypto.subtle.sign('HMAC',key,messageBuffer)));
}

function standardMessage(timestamp:number,rawBody:Uint8Array):Uint8Array {
  const prefix=encoder.encode(String(timestamp)+'.');
  const message=new Uint8Array(prefix.length+rawBody.length);
  message.set(prefix,0);
  message.set(rawBody,prefix.length);
  return message;
}

describe('Paystack candidate webhook verification',()=>{
  const rawBody=encoder.encode('{"event":"charge.success","data":{"amount":12500,"reference":"GOOBT-123"}}');
  const now=1700000000;

  it('verifies the current timestamped Paystack-Signature header',async()=>{
    const secret='whsec_test_secret';
    const signature=await sign(secret,standardMessage(now,rawBody));
    const result=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now},v1=whk_test:${signature}`},{webhook_secrets:[secret]},now);
    expect(result).toEqual({valid:true,mode:'standard',key_id:'whk_test'});
  });

  it('supports rotating secrets and multiple v1 signatures',async()=>{
    const oldSecret='whsec_old_secret';
    const activeSecret='whsec_active_secret';
    const oldSignature=await sign(oldSecret,standardMessage(now,rawBody));
    const activeSignature=await sign(activeSecret,standardMessage(now,rawBody));
    const header=`t=${now},v1=whk_old:${oldSignature},v1=whk_active:${activeSignature}`;
    const result=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:header},{webhook_secrets:[activeSecret]},now);
    expect(result).toEqual({valid:true,mode:'standard',key_id:'whk_active'});
  });

  it('rejects stale/future timestamps and duplicate timestamp fields',async()=>{
    const secret='whsec_test_secret';
    const signature=await sign(secret,standardMessage(now,rawBody));
    const stale=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now-301},v1=whk_test:${await sign(secret,standardMessage(now-301,rawBody))}`},{webhook_secrets:[secret]},now);
    const future=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now+301},v1=whk_test:${await sign(secret,standardMessage(now+301,rawBody))}`},{webhook_secrets:[secret]},now);
    const duplicate=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now},t=${now},v1=whk_test:${signature}`},{webhook_secrets:[secret]},now);
    expect(stale.valid).toBe(false);
    expect(future.valid).toBe(false);
    expect(duplicate.valid).toBe(false);
  });

  it('rejects malformed headers, missing secrets and altered raw body bytes',async()=>{
    const secret='whsec_test_secret';
    const signature=await sign(secret,standardMessage(now,rawBody));
    const malformed=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=bad,v1=whk_test:${signature}`},{webhook_secrets:[secret]},now);
    const missingSecret=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now},v1=whk_test:${signature}`},{webhook_secrets:[]},now);
    const alteredBody=encoder.encode('{"event":"charge.success", "data":{"amount":12500,"reference":"GOOBT-123"}}');
    const altered=await verifyPaystackWebhookSignature(alteredBody,{paystack_signature:`t=${now},v1=whk_test:${signature}`},{webhook_secrets:[secret]},now);
    expect(malformed.valid).toBe(false);
    expect(missingSecret.valid).toBe(false);
    expect(altered.valid).toBe(false);
  });

  it('verifies the legacy x-paystack-signature header against the raw body',async()=>{
    const secret='sk_test_legacy_key';
    const signature=await sign(secret,rawBody);
    const result=await verifyPaystackWebhookSignature(rawBody,{x_paystack_signature:signature},{secret_key:secret},now);
    expect(result).toEqual({valid:true,mode:'legacy'});
  });

  it('rejects invalid legacy signatures and does not downgrade an invalid standard header',async()=>{
    const secret='sk_test_legacy_key';
    const validLegacy=await sign(secret,rawBody);
    const invalidStandard='a'.repeat(128);
    const invalid=await verifyPaystackWebhookSignature(rawBody,{x_paystack_signature:'invalid'},{secret_key:secret},now);
    const noDowngrade=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${now},v1=whk_test:${invalidStandard}`,x_paystack_signature:validLegacy},{webhook_secrets:['whsec_other'],secret_key:secret},now);
    expect(invalid.valid).toBe(false);
    expect(noDowngrade).toEqual({valid:false,mode:'standard'});
  });

  it('accepts signatures at the exact timestamp tolerance boundary',async()=>{
    const secret='whsec_test_secret';
    const timestamp=now-300;
    const signature=await sign(secret,standardMessage(timestamp,rawBody));
    const result=await verifyPaystackWebhookSignature(rawBody,{paystack_signature:`t=${timestamp},v1=whk_test:${signature}`},{webhook_secrets:[secret]},now);
    expect(result.valid).toBe(true);
  });
});
