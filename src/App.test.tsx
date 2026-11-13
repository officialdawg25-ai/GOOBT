import {describe,it,expect} from 'vitest';
import {calculateLineTotalMinor,calculateSubtotalMinor,formatCurrencyMinor} from './lib/commerce';

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
