export function calculateLineTotalMinor(unitPriceMinor:number,quantity:number):number {
  if(!Number.isSafeInteger(unitPriceMinor)||unitPriceMinor<0) throw new RangeError('unit price must be a non-negative safe integer in minor units');
  if(!Number.isSafeInteger(quantity)||quantity<1) throw new RangeError('quantity must be a positive safe integer');
  const total=unitPriceMinor*quantity;
  if(!Number.isSafeInteger(total)) throw new RangeError('line total exceeds safe integer range');
  return total;
}

export function calculateSubtotalMinor<T>(items:readonly T[],getLineTotal:(item:T)=>number):number {
  let subtotal=0;
  for(const item of items){
    const lineTotal=getLineTotal(item);
    if(!Number.isSafeInteger(lineTotal)||lineTotal<0) throw new RangeError('line total must be a non-negative safe integer in minor units');
    subtotal+=lineTotal;
    if(!Number.isSafeInteger(subtotal)) throw new RangeError('subtotal exceeds safe integer range');
  }
  return subtotal;
}

export function formatCurrencyMinor(amountMinor:number,currency='ZAR',locale='en-ZA'):string {
  if(!Number.isSafeInteger(amountMinor)) throw new RangeError('amount must be a safe integer in minor units');
  return new Intl.NumberFormat(locale,{style:'currency',currency}).format(amountMinor/100);
}
