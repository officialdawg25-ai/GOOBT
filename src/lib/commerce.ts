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

export type PromotionDraftInput={code:string;discountType:'percentage'|'fixed';discountValue:string|number;usageLimit?:string|number|null;startsAt?:string|null;endsAt?:string|null};

export function normalizePromotionCode(code:string):string {
  return code.trim().toUpperCase().replace(/[^A-Z0-9-]/g,'');
}

export function validatePromotionDraft(input:PromotionDraftInput):string|null {
  if(!normalizePromotionCode(input.code)) return 'promotion code is required and must contain letters, digits or hyphens';
  const value=typeof input.discountValue==='number'?input.discountValue:Number(input.discountValue);
  if(!Number.isSafeInteger(value)||value<=0) return 'discount value must be a positive whole number';
  if(input.discountType==='percentage'&&value>100) return 'percentage discount cannot exceed 100';
  const limit=input.usageLimit==null||String(input.usageLimit).trim()===''?null:(typeof input.usageLimit==='number'?input.usageLimit:Number(input.usageLimit));
  if(limit!==null&&(!Number.isSafeInteger(limit)||limit<1)) return 'usage limit must be a positive whole number';
  const start=input.startsAt?new Date(input.startsAt).getTime():null;
  const end=input.endsAt?new Date(input.endsAt).getTime():null;
  if(start!==null&&!Number.isFinite(start)) return 'start date is invalid';
  if(end!==null&&!Number.isFinite(end)) return 'end date is invalid';
  if(start!==null&&end!==null&&end<=start) return 'promotion end must be later than its start';
  return null;
}

export function filterCatalogueProducts<T extends {division_id:string;name:string;description:string|null}>(products:readonly T[],query:string,divisionId:string|null=null):T[] {
  const normalizedQuery=query.trim().toLowerCase();
  return products.filter(product=>(divisionId===null||product.division_id===divisionId)&&(!normalizedQuery||product.name.toLowerCase().includes(normalizedQuery)||(product.description??'').toLowerCase().includes(normalizedQuery)));
}
