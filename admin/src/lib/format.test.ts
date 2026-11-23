import { describe, expect, it } from 'vitest';
import {
  formatDate,
  formatDateTime,
  formatDay,
  formatPaise,
  fromIndiaInput,
  groupIndian,
  indiaDay,
  parseRupees,
  rupeesInput,
  toIndiaInput,
} from './format';

describe('formatPaise', () => {
  it('formats zero and paise', () => {
    expect(formatPaise(0)).toBe('₹0');
    expect(formatPaise(5)).toBe('₹0.05');
    expect(formatPaise(50)).toBe('₹0.50');
  });

  it('groups thousands, lakhs and crores the Indian way', () => {
    expect(formatPaise(100000)).toBe('₹1,000');
    expect(formatPaise(18500000)).toBe('₹1,85,000');
    expect(formatPaise(1000000000)).toBe('₹1,00,00,000');
    expect(formatPaise(123456789012)).toBe('₹1,23,45,67,890.12');
  });

  it('uses a minus sign for negatives', () => {
    expect(formatPaise(-500000)).toBe('−₹5,000');
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
  it("formats on India's clock, whatever the viewer's", () => {
    expect(formatDate('2026-10-18T12:00:00Z')).toBe('18 Oct 2026');
    expect(formatDate('2026-01-04T18:30:00Z')).toBe('5 Jan 2026');
    expect(formatDateTime('2026-10-18T08:35:00Z')).toBe('18 Oct 2026, 14:05');
    expect(formatDateTime('2026-10-17T18:30:00Z')).toBe('18 Oct 2026, 00:00');
    expect(formatDay('2026-09-05')).toBe('5 Sep 2026');
  });

  it('reads and writes date fields as Indian time', () => {
    expect(indiaDay(0, new Date('2026-11-22T18:29:00Z'))).toBe('2026-11-22');
    expect(indiaDay(0, new Date('2026-11-22T18:30:00Z'))).toBe('2026-11-23');
    expect(indiaDay(7, new Date('2026-11-28T00:00:00Z'))).toBe('2026-12-05');
    expect(toIndiaInput('2026-11-22T20:00:00Z')).toBe('2026-11-23T01:30');
    expect(fromIndiaInput('2026-11-23T01:30')).toBe('2026-11-22T20:00:00.000Z');
  });
});

describe('parseRupees', () => {
  it.each([
    ['1,85,000', 18_500_000],
    ['4.55', 455],
    ['4.5', 450],
    ['0.07', 7],
    ['₹ 78,000', 7_800_000],
    ['0', 0],
    ['1.15', 115],
  ])('%s is exact paise', (text, paise) => {
    expect(parseRupees(text)).toBe(paise);
  });

  it.each(['', '-5', '4.555', '1e3', 'abc', '.5', '5.', '1234567890123'])(
    '"%s" is no amount',
    (text) => {
      expect(parseRupees(text)).toBeUndefined();
    },
  );

  it('fills a field without losing paise', () => {
    for (const paise of [0, 5, 455, 450, 18_500_000]) {
      expect(parseRupees(rupeesInput(paise))).toBe(paise);
    }
  });
});
