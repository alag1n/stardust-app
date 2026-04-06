import { Timestamp } from 'firebase/firestore';

export interface User {
  id: string;
  email: string;
  coins: number;
  energy: number;
  pet_id: string;
  friends: string[];
  created_at: Timestamp;
}
