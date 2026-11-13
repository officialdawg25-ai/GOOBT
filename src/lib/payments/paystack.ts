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
