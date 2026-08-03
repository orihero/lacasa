import { describe, expect, it } from 'vitest';
import { adInputSchema } from './ad';

describe('adInputSchema', () => {
  it('accepts a full, well-formed ad payload', () => {
    const parsed = adInputSchema.parse({
      title: 'Cozy 2-room flat',
      city: 'Tashkent',
      district: 'Chilonzor',
      type: 'residential',
      category: 'rent',
      repairment: 'good',
      rooms: '2',
      area: '54.5',
      storey: '3',
      floors: '9',
      furniture: 'withFurniture',
      hashtags: '#new',
      price: '1000',
      priceType: 'usd',
      stage: '1',
      nearPlacesList: ['school'],
      optionList: [{ id: 1, key: 'balcony', value: 'yes' }],
      active: true,
      photos: ['https://example.com/a.jpg'],
    });
    expect(parsed.rooms).toBe(2);
    expect(parsed.area).toBe(54.5);
    expect(parsed.stage).toBe('1');
  });

  it('accepts an empty object (every field optional, for PATCH)', () => {
    expect(adInputSchema.parse({})).toEqual({});
  });

  it('turns an empty string on a nullable numeric field into null, not 0', () => {
    const parsed = adInputSchema.parse({ rooms: '' });
    expect(parsed.rooms).toBeNull();
  });

  it('turns an empty string on a nullable text field into null', () => {
    const parsed = adInputSchema.parse({ address: '' });
    expect(parsed.address).toBeNull();
  });

  it('rejects a type value outside AD_TYPE keys', () => {
    expect(() => adInputSchema.parse({ type: 'RESIDENTIAL' })).toThrow();
  });

  it('rejects a negative price', () => {
    expect(() => adInputSchema.parse({ price: -5 })).toThrow();
  });

  it('rejects an empty title', () => {
    expect(() => adInputSchema.parse({ title: '' })).toThrow();
  });

  it('coerces lat/lng strings to numbers, empty string to null', () => {
    const parsed = adInputSchema.parse({ lat: '41.311081', lng: '' });
    expect(parsed.lat).toBe(41.311081);
    expect(parsed.lng).toBeNull();
  });

  it('rejects a latitude outside -90..90', () => {
    expect(() => adInputSchema.parse({ lat: 91 })).toThrow();
    expect(() => adInputSchema.parse({ lat: -91 })).toThrow();
  });

  it('rejects a longitude outside -180..180', () => {
    expect(() => adInputSchema.parse({ lng: 181 })).toThrow();
    expect(() => adInputSchema.parse({ lng: -181 })).toThrow();
  });

  it('accepts boundary lat/lng values', () => {
    expect(adInputSchema.parse({ lat: 90, lng: 180 })).toEqual({ lat: 90, lng: 180 });
    expect(adInputSchema.parse({ lat: -90, lng: -180 })).toEqual({ lat: -90, lng: -180 });
  });
});
