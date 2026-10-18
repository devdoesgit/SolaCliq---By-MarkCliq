import { describe, expect, it } from 'vitest';
import { formatDate, formatDateTime, formatPaise, groupIndian } from './format';

describe('formatPaise', () => {
  it('formats zero and paise', () => {
    expect(formatPaise(0)).toBe('₹0.00');
    expect(formatPaise(5)).toBe('₹0.05');
    expect(formatPaise(50)).toBe('₹0.50');
  });

  it('groups thousands, lakhs and crores the Indian way', () => {
    expect(formatPaise(100000)).toBe('₹1,000.00');
    expect(formatPaise(18500000)).toBe('₹1,85,000.00');
    expect(formatPaise(1000000000)).toBe('₹1,00,00,000.00');
    expect(formatPaise(123456789012)).toBe('₹1,23,45,67,890.12');
  });

  it('uses a minus sign for negatives', () => {
    expect(formatPaise(-500000)).toBe('−₹5,000.00');
    expect(formatPaise(-1)).toBe('−₹0.01');
  });

  it('handles int64 limits as bigint', () => {
    expect(formatPaise(9223372036854775807n)).toBe('₹92,23,37,20,36,85,47,758.07');
    expect(formatPaise(-9223372036854775808n)).toBe('−₹92,23,37,20,36,85,47,758.08');
  });

  it('rejects unsafe numbers instead of rounding money', () => {
    expect(() => formatPaise(2 ** 60)).toThrow(RangeError);
    expect(() => formatPaise(1.5)).toThrow(RangeError);
  });
});

describe('groupIndian', () => {
  it('groups in twos before the last three', () => {
    expect(groupIndian('123')).toBe('123');
    expect(groupIndian('1234')).toBe('1,234');
    expect(groupIndian('123456')).toBe('1,23,456');
    expect(groupIndian('1234567')).toBe('12,34,567');
  });
});

describe('formatDate', () => {
  it('formats day month year and 24-hour time', () => {
    expect(formatDate(new Date(2026, 9, 18))).toBe('18 Oct 2026');
    expect(formatDate(new Date(2026, 0, 5))).toBe('5 Jan 2026');
    expect(formatDateTime(new Date(2026, 9, 18, 14, 5))).toBe('18 Oct 2026, 14:05');
    expect(formatDateTime(new Date(2026, 9, 18, 0, 0))).toBe('18 Oct 2026, 00:00');
  });
});
