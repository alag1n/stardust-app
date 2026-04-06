import { Timestamp } from 'firebase/firestore';

export interface Pet {
  id: string;
  owner_id: string;
  name: string;
  type: string;
  level: number;
  xp: number;
  health: number;
  hunger: number;
  energy: number;
  mood: number;
  created_at: Timestamp;
}
