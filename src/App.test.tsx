import {describe,it,expect} from 'vitest';
import {calculateLineTotalMinor,calculateSubtotalMinor,formatCurrencyMinor,normalizePromotionCode,validatePromotionDraft,filterCatalogueProducts,parseZarToMinor} from './lib/commerce';

describe('GOOBT commerce arithmetic',()=>{
  it('calculates line totals in integer minor units without floating-point drift',()=>{
    expect(calculateLineTotalMinor(2599,3)).toBe(7797);
    expect(calculateLineTotalMinor(1,7)).toBe(7);
  });
  it('rejects invalid unit prices and quantities',()=>{
    expect(()=>calculateLineTotalMinor(-1,1)).toThrow(RangeError);
    expect(()=>calculateLineTotalMinor(100,0)).toThrow(RangeError);
    expect(()=>calculateLineTotalMinor(100,1.5)).toThrow(RangeError);
  });
  it('rejects a line total that exceeds the safe integer range',()=>{
    expect(()=>calculateLineTotalMinor(Number.MAX_SAFE_INTEGER,2)).toThrow(RangeError);
  });
  it('sums line totals safely and returns zero for an empty cart',()=>{
    const lines=[{price:2599,quantity:3},{price:100,quantity:1}];
    expect(calculateSubtotalMinor(lines,line=>calculateLineTotalMinor(line.price,line.quantity))).toBe(7897);
    expect(calculateSubtotalMinor([],()=>0)).toBe(0);
  });
  it('rejects unsafe or negative line totals when calculating subtotal',()=>{
    expect(()=>calculateSubtotalMinor([-1],line=>line)).toThrow(RangeError);
    expect(()=>calculateSubtotalMinor([Number.MAX_SAFE_INTEGER,1],line=>line)).toThrow(RangeError);
  });
  it('formats ZAR and other currencies from integer minor units',()=>{
    expect(formatCurrencyMinor(2599)).toContain('R');
    expect(formatCurrencyMinor(12345,'USD','en-US')).toContain('$');
  });
  it('rejects invalid currency amounts/codes',()=>{
    expect(()=>formatCurrencyMinor(1.2)).toThrow(RangeError);
    expect(()=>formatCurrencyMinor(100,'INVALID')).toThrow(RangeError);
  });
});

describe('GOOBT promotion draft validation',()=>{
  it('normalizes codes to uppercase and strips unsupported characters',()=>{
    expect(normalizePromotionCode(' welcome_10! ')).toBe('WELCOME10');
  });
  it('accepts a valid percentage promotion draft',()=>{
    expect(validatePromotionDraft({code:'SAVE10',discountType:'percentage',discountValue:'10',usageLimit:'100',startsAt:'2026-11-13T10:00',endsAt:'2026-11-14T10:00'})).toBeNull();
  });
  it('rejects percentage discounts above 100 and nonpositive values',()=>{
    expect(validatePromotionDraft({code:'SAVE',discountType:'percentage',discountValue:101})).not.toBeNull();
    expect(validatePromotionDraft({code:'SAVE',discountType:'fixed',discountValue:0})).not.toBeNull();
  });
  it('rejects malformed codes and usage limits',()=>{
    expect(validatePromotionDraft({code:'***',discountType:'fixed',discountValue:100})).not.toBeNull();
    expect(validatePromotionDraft({code:'SAVE',discountType:'fixed',discountValue:100,usageLimit:'-2'})).not.toBeNull();
  });
  it('rejects reversed and invalid date ranges',()=>{
    expect(validatePromotionDraft({code:'SAVE',discountType:'fixed',discountValue:100,startsAt:'2026-11-14T10:00',endsAt:'2026-11-13T10:00'})).not.toBeNull();
    expect(validatePromotionDraft({code:'SAVE',discountType:'fixed',discountValue:100,startsAt:'not-a-date'})).not.toBeNull();
  });
});

describe('GOOBT live catalogue filtering',()=>{
  const products=[
    {id:'a',division_id:'food',name:'Harvest Apples',description:'Fresh produce'},
    {id:'b',division_id:'beauty',name:'Daily Moisturizer',description:'Hydrating skincare'},
    {id:'c',division_id:'food',name:'Wholegrain Bread',description:null}
  ];
  it('filters by active division without leaking other division products',()=>{
    expect(filterCatalogueProducts(products,'','food').map(p=>p.id)).toEqual(['a','c']);
  });
  it('searches product names and descriptions case-insensitively',()=>{
    expect(filterCatalogueProducts(products,'HYDRATING').map(p=>p.id)).toEqual(['b']);
    expect(filterCatalogueProducts(products,'apples').map(p=>p.id)).toEqual(['a']);
  });
  it('combines division filter and search, and leaves all divisions when unset',()=>{
    expect(filterCatalogueProducts(products,'bread','food').map(p=>p.id)).toEqual(['c']);
    expect(filterCatalogueProducts(products,'',null).map(p=>p.id)).toEqual(['a','b','c']);
  });
  it('filters by category alongside the division scope',()=>{
    const categorized=[{...products[0],category_id:'fresh'},{...products[1],category_id:'skincare'},{...products[2],category_id:'bakery'}];
    expect(filterCatalogueProducts(categorized,'','food','fresh').map(p=>p.id)).toEqual(['a']);
    expect(filterCatalogueProducts(categorized,'','food','bakery').map(p=>p.id)).toEqual(['c']);
  });
});

describe('GOOBT ZAR input parsing',()=>{
  it('parses decimal ZAR prices to exact integer minor units',()=>{
    expect(parseZarToMinor('0')).toBe(0);
    expect(parseZarToMinor('1')).toBe(100);
    expect(parseZarToMinor('1.9')).toBe(190);
    expect(parseZarToMinor('2599.00')).toBe(259900);
    expect(parseZarToMinor('0.05')).toBe(5);
  });
  it('rejects negative, malformed, excessive precision and unsafe prices',()=>{
    expect(parseZarToMinor('-1')).toBeNull();
    expect(parseZarToMinor('1.999')).toBeNull();
    expect(parseZarToMinor('R20')).toBeNull();
    expect(parseZarToMinor('')).toBeNull();
    expect(parseZarToMinor('9007199254740992')).toBeNull();
  });
});
