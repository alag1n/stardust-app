import { Timestamp } from 'firebase/firestore';

export interface Item {
  id: string;
  name: string;
  type: 'food' | 'toy' | 'clothing';
  price_coins: number;
  effect: { stat: string, value: number };
}
