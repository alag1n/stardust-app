import { doc, getDoc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

export async function getPet(petId: string) {
  const petRef = doc(db, 'pets', petId);
  const petSnapshot = await getDoc(petRef);
  if (petSnapshot.exists()) {
    return petSnapshot.data() as Pet;
  }
  throw new Error('Питомец не найден');
}

export async function updatePetStats(petId: string, updates: Partial<Pet>) {
  const petRef = doc(db, 'pets', petId);
  await updateDoc(petRef, updates);
}
