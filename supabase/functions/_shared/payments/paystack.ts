/**
 * Server-side-only Paystack candidate adapter.
 *
 * Do not import this module into browser/UI code. It is intentionally not wired
 * to GOOBT's payment-intent Edge Function until provider, merchant-of-record,
 * split-settlement and legal decisions are approved. No credentials are stored here.
 */
export type PaystackSplitInput = {
  type: 'flat' | 'percentage';
  bearer_type: 'account' | 'all' | 'all-proportional' | 'subaccount';
  subaccounts: Array<{ subaccount: string; share: number }>;
  bearer_subaccount?: string;
  reference?: string;
};

export type PaystackInitializeInput = {
  secret_key: string;
  email: string;
  amount_minor: number;
  currency: 'ZAR';
  reference: string;
  callback_url: string;
  allowed_callback_origins: readonly string[];
  metadata: Record<string, unknown>;
  channels?: string[];
  split?: PaystackSplitInput;
  timeout_ms?: number;
};

export type PaystackInitializeResult = {
  authorization_url: string;
  access_code: string;
  reference: string;
};

const REFERENCE_PATTERN = /^[A-Za-z0-9-=.]{1,100}$/;
const SUBACCOUNT_PATTERN = /^ACCT_[A-Za-z0-9_-]+$/;
const CHANNELS = new Set([
  'card','bank','apple_pay','ussd','qr','mobile_money','bank_transfer',
  'eft','capitec_pay','payattitude'
]);

function validateSplit(split: PaystackSplitInput, amountMinor: number): void {
  if (!Array.isArray(split.subaccounts) || split.subaccounts.length === 0) {
    throw new RangeError('split must include at least one subaccount');
  }
  const seen = new Set<string>();
  let total = 0;
  for (const recipient of split.subaccounts) {
    if (!SUBACCOUNT_PATTERN.test(recipient.subaccount)) {
      throw new RangeError('split contains an invalid Paystack subaccount code');
    }
    if (seen.has(recipient.subaccount)) {
      throw new RangeError('split contains a duplicate subaccount');
    }
    seen.add(recipient.subaccount);
    if (!Number.isSafeInteger(recipient.share) || recipient.share <= 0) {
      throw new RangeError('split shares must be positive safe integers');
    }
    total += recipient.share;
    if (!Number.isSafeInteger(total)) {
      throw new RangeError('split share total exceeds safe integer range');
    }
  }
  if (split.type === 'flat' && total > amountMinor) {
    throw new RangeError('flat split shares cannot exceed the transaction amount');
  }
  if (split.type === 'percentage' && total > 100) {
    throw new RangeError('percentage split shares cannot exceed 100');
  }
  if (split.bearer_type === 'subaccount') {
    if (!split.bearer_subaccount || !seen.has(split.bearer_subaccount)) {
      throw new RangeError('subaccount fee bearer must be included in the split recipients');
    }
  } else if (split.bearer_subaccount) {
    throw new RangeError('bearer_subaccount is only valid when bearer_type is subaccount');
  }
  if (split.reference && !REFERENCE_PATTERN.test(split.reference)) {
    throw new RangeError('split reference contains unsupported characters');
  }
}

function validateInput(input: PaystackInitializeInput): void {
  if (!input.secret_key.trim()) throw new Error('PAYSTACK_SECRET_KEY is not configured');
  if (!Number.isSafeInteger(input.amount_minor) || input.amount_minor <= 0) {
    throw new RangeError('transaction amount must be a positive safe integer in minor units');
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.email)) {
    throw new RangeError('customer email is invalid');
  }
  if (!REFERENCE_PATTERN.test(input.reference)) {
    throw new RangeError('transaction reference contains unsupported characters');
  }
  let callback: URL;
  try {
    callback = new URL(input.callback_url);
  } catch {
    throw new RangeError('callback URL is invalid');
  }
  if (callback.protocol !== 'https:' || callback.username || callback.password || callback.hash) {
    throw new RangeError('callback URL must be HTTPS without credentials or a fragment');
  }
  if (!input.allowed_callback_origins.length || !input.allowed_callback_origins.includes(callback.origin)) {
    throw new RangeError('callback URL origin is not allow-listed');
  }
  if (input.channels && input.channels.some(channel => !CHANNELS.has(channel))) {
    throw new RangeError('transaction contains an unsupported payment channel');
  }
  if (input.split) validateSplit(input.split, input.amount_minor);
  const timeout = input.timeout_ms ?? 15000;
  if (!Number.isSafeInteger(timeout) || timeout < 1000 || timeout > 30000) {
    throw new RangeError('timeout must be between 1000 and 30000 milliseconds');
  }
}

export async function initializePaystackCandidate(
  input: PaystackInitializeInput,
  fetcher: typeof fetch = fetch
): Promise<PaystackInitializeResult> {
  validateInput(input);
  const body: Record<string, unknown> = {
    email: input.email,
    amount: String(input.amount_minor),
    currency: input.currency,
    reference: input.reference,
    callback_url: input.callback_url,
    metadata: JSON.stringify(input.metadata)
  };
  if (input.channels?.length) body.channels = input.channels;
  if (input.split) body.split = input.split;

  let response: Response;
  try {
    response = await fetcher('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + input.secret_key,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(input.timeout_ms ?? 15000)
    });
  } catch {
    throw new Error('paystack_transaction_initialization_network_error');
  }

  let payload: { status?: boolean; message?: string; data?: { authorization_url?: string; access_code?: string; reference?: string } };
  try {
    payload = await response.json() as typeof payload;
  } catch {
    throw new Error('paystack_transaction_initialization_invalid_response');
  }
  const data = payload.data;
  if (!response.ok || payload.status !== true || !data?.authorization_url || !data.access_code || !data.reference) {
    throw new Error('paystack_transaction_initialization_failed_http_' + response.status);
  }
  if (data.reference !== input.reference) {
    throw new Error('paystack_transaction_reference_mismatch');
  }
  let authorizationUrl: URL;
  try {
    authorizationUrl = new URL(data.authorization_url);
  } catch {
    throw new Error('paystack_authorization_url_invalid');
  }
  if (authorizationUrl.protocol !== 'https:' || authorizationUrl.hostname !== 'checkout.paystack.com') {
    throw new Error('paystack_authorization_url_origin_invalid');
  }
  return {
    authorization_url: authorizationUrl.toString(),
    access_code: data.access_code,
    reference: data.reference
  };
}

export type PaystackWebhookVerification = {
  valid: boolean;
  mode: 'standard' | 'legacy' | 'none';
  key_id?: string;
};

const WEBHOOK_SIGNATURE_HEX = /^[0-9a-f]{128}$/;
const WEBHOOK_TIMESTAMP_TOLERANCE_SECONDS = 300;

function decodeSignatureHex(hex:string):Uint8Array|null {
  if(!WEBHOOK_SIGNATURE_HEX.test(hex)) return null;
  const bytes=new Uint8Array(64);
  for(let i=0;i<64;i++) bytes[i]=Number.parseInt(hex.slice(i*2,i*2+2),16);
  return bytes;
}

function constantTimeBytesEqual(left:Uint8Array,right:Uint8Array):boolean {
  if(left.length!==right.length) return false;
  let mismatch=0;
  for(let i=0;i<left.length;i++) mismatch|=left[i]^right[i];
  return mismatch===0;
}

async function hmacSha512(secret:string,message:Uint8Array):Promise<Uint8Array> {
  const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(secret),{name:'HMAC',hash:'SHA-512'},false,['sign']);
  const messageCopy=new Uint8Array(message.byteLength);messageCopy.set(message);const messageBuffer:ArrayBuffer=messageCopy.buffer;return new Uint8Array(await crypto.subtle.sign('HMAC',key,messageBuffer));
}

function parseStandardSignatureHeader(header:string,nowSeconds:number):{timestamp:string;entries:Array<{key_id:string;signature:string}>}|null {
  let timestamp:string|null=null;
  const entries:Array<{key_id:string;signature:string}>=[];
  for(const part of header.split(',')){
    const separator=part.indexOf('=');
    if(separator<0) continue;
    const name=part.slice(0,separator).trim();
    const value=part.slice(separator+1).trim();
    if(name==='t'){
      if(timestamp!==null||!/^\d+$/.test(value)) return null;
      const numeric=Number(value);
      if(!Number.isSafeInteger(numeric)||Math.abs(nowSeconds-numeric)>WEBHOOK_TIMESTAMP_TOLERANCE_SECONDS) return null;
      timestamp=value;
    }else if(name==='v1'){
      const colon=value.indexOf(':');
      if(colon<=0) continue;
      const keyId=value.slice(0,colon);
      const signature=value.slice(colon+1);
      if(!keyId.startsWith('whk_')||!WEBHOOK_SIGNATURE_HEX.test(signature)) continue;
      entries.push({key_id:keyId,signature});
    }
  }
  if(timestamp===null||entries.length===0) return null;
  return {timestamp,entries};
}

/**
 * Verify Paystack's current Paystack-Signature header (timestamped, rotating
 * whsec secrets) or its legacy x-paystack-signature header (secret-key HMAC).
 * The raw request bytes must be supplied before JSON parsing.
 *
 * If the current header is present but invalid, verification fails closed and
 * does not downgrade to the legacy header.
 */
export async function verifyPaystackWebhookSignature(
  rawBody:Uint8Array,
  headers:{paystack_signature?:string|null;x_paystack_signature?:string|null},
  secrets:{webhook_secrets?:readonly string[];secret_key?:string|null},
  nowSeconds=Math.floor(Date.now()/1000)
):Promise<PaystackWebhookVerification>{
  const standardHeader=headers.paystack_signature?.trim();
  if(standardHeader){
    if(!Number.isSafeInteger(nowSeconds)) return {valid:false,mode:'standard'};
    const parsed=parseStandardSignatureHeader(standardHeader,nowSeconds);
    if(!parsed||!secrets.webhook_secrets?.length) return {valid:false,mode:'standard'};
    const prefix=new TextEncoder().encode(parsed.timestamp+'.');
    const message=new Uint8Array(prefix.length+rawBody.length);
    message.set(prefix,0);
    message.set(rawBody,prefix.length);
    for(const secret of secrets.webhook_secrets){
      if(!secret) continue;
      let expected:Uint8Array;
      try{expected=await hmacSha512(secret,message);}catch{return {valid:false,mode:'standard'};}
      for(const entry of parsed.entries){
        const candidate=decodeSignatureHex(entry.signature);
        if(candidate&&constantTimeBytesEqual(expected,candidate)) return {valid:true,mode:'standard',key_id:entry.key_id};
      }
    }
    return {valid:false,mode:'standard'};
  }
  const legacyHeader=headers.x_paystack_signature?.trim();
  if(legacyHeader){
    if(!WEBHOOK_SIGNATURE_HEX.test(legacyHeader)||!secrets.secret_key) return {valid:false,mode:'legacy'};
    const candidate=decodeSignatureHex(legacyHeader);
    if(!candidate) return {valid:false,mode:'legacy'};
    try{
      const expected=await hmacSha512(secrets.secret_key,rawBody);
      return {valid:constantTimeBytesEqual(expected,candidate),mode:'legacy'};
    }catch{return {valid:false,mode:'legacy'};}
  }
  return {valid:false,mode:'none'};
}
