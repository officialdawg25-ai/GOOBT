import {describe,it,expect,vi} from 'vitest';
import {initializePaystackCandidate,type PaystackInitializeInput} from '../../../supabase/functions/_shared/payments/paystack.ts';

const validInput:PaystackInitializeInput={
  secret_key:'sk_test_candidate_secret',
  email:'buyer@example.com',
  amount_minor:12500,
  currency:'ZAR',
  reference:'GOOBT-ORDER-123',
  callback_url:'https://goobt.example/payments/callback',
  allowed_callback_origins:['https://goobt.example'],
  metadata:{order_id:'order-123',source:'goobt'},
  timeout_ms:5000
};

function response(payload:unknown,status=200):Response {
  return new Response(JSON.stringify(payload),{status,headers:{'Content-Type':'application/json'}});
}

describe('Paystack candidate adapter',()=>{
  it('initializes with server-side key and exact minor-unit amount, then returns verified checkout details',async()=>{
    const fetcher=vi.fn<typeof fetch>().mockResolvedValue(response({status:true,message:'Authorization URL created',data:{authorization_url:'https://checkout.paystack.com/session123',access_code:'session123',reference:validInput.reference}}));
    const result=await initializePaystackCandidate(validInput,fetcher);
    expect(fetcher).toHaveBeenCalledTimes(1);
    const [url,init]=fetcher.mock.calls[0];
    expect(url).toBe('https://api.paystack.co/transaction/initialize');
    expect(init?.method).toBe('POST');
    expect(new Headers(init?.headers).get('Authorization')).toBe('Bearer sk_test_candidate_secret');
    const body=JSON.parse(String(init?.body));
    expect(body.amount).toBe('12500');
    expect(body.currency).toBe('ZAR');
    expect(body.reference).toBe(validInput.reference);
    expect(body.metadata).toBe(JSON.stringify(validInput.metadata));
    expect(result).toEqual({authorization_url:'https://checkout.paystack.com/session123',access_code:'session123',reference:validInput.reference});
  });

  it('sends a valid flat multi-recipient split explicitly, without choosing fee policy implicitly',async()=>{
    const split={type:'flat' as const,bearer_type:'account' as const,subaccounts:[{subaccount:'ACCT_merchantA',share:7500},{subaccount:'ACCT_merchantB',share:5000}]};
    const fetcher=vi.fn<typeof fetch>().mockResolvedValue(response({status:true,data:{authorization_url:'https://checkout.paystack.com/split123',access_code:'split123',reference:validInput.reference}}));
    await initializePaystackCandidate({...validInput,split},fetcher);
    expect(JSON.parse(String(fetcher.mock.calls[0][1]?.body)).split).toEqual(split);
  });

  it('rejects invalid amounts, references, callback origins and payment channels before network call',async()=>{
    const fetcher=vi.fn<typeof fetch>();
    await expect(initializePaystackCandidate({...validInput,amount_minor:0},fetcher)).rejects.toThrow(RangeError);
    await expect(initializePaystackCandidate({...validInput,reference:'bad reference'},fetcher)).rejects.toThrow(RangeError);
    await expect(initializePaystackCandidate({...validInput,callback_url:'https://evil.example/callback'},fetcher)).rejects.toThrow(RangeError);
    await expect(initializePaystackCandidate({...validInput,channels:['cash']},fetcher)).rejects.toThrow(RangeError);
    expect(fetcher).not.toHaveBeenCalled();
  });

  it('rejects flat splits exceeding the transaction total and invalid recipients',async()=>{
    const fetcher=vi.fn<typeof fetch>();
    const overSplit={type:'flat' as const,bearer_type:'account' as const,subaccounts:[{subaccount:'ACCT_a',share:8000},{subaccount:'ACCT_b',share:5000}]};
    await expect(initializePaystackCandidate({...validInput,split:overSplit},fetcher)).rejects.toThrow(RangeError);
    const duplicate={type:'flat' as const,bearer_type:'account' as const,subaccounts:[{subaccount:'ACCT_a',share:1000},{subaccount:'ACCT_a',share:1000}]};
    await expect(initializePaystackCandidate({...validInput,split:duplicate},fetcher)).rejects.toThrow(RangeError);
    expect(fetcher).not.toHaveBeenCalled();
  });

  it('rejects a malformed or mismatched provider response',async()=>{
    const fetcher=vi.fn<typeof fetch>().mockResolvedValue(response({status:true,data:{authorization_url:'http://checkout.paystack.com/x',access_code:'x',reference:validInput.reference}}));
    await expect(initializePaystackCandidate(validInput,fetcher)).rejects.toThrow('paystack_authorization_url_origin_invalid');
    const mismatch=vi.fn<typeof fetch>().mockResolvedValue(response({status:true,data:{authorization_url:'https://checkout.paystack.com/x',access_code:'x',reference:'OTHER'}}));
    await expect(initializePaystackCandidate(validInput,mismatch)).rejects.toThrow('paystack_transaction_reference_mismatch');
  });

  it('fails closed on provider HTTP errors and network exceptions without leaking secret key',async()=>{
    const httpError=vi.fn<typeof fetch>().mockResolvedValue(response({status:false,message:'Declined'},400));
    await expect(initializePaystackCandidate(validInput,httpError)).rejects.toThrow('paystack_transaction_initialization_failed_http_400');
    const network=vi.fn<typeof fetch>().mockRejectedValue(new Error('network'));
    await expect(initializePaystackCandidate(validInput,network)).rejects.toThrow('paystack_transaction_initialization_network_error');
  });
});
