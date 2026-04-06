import { doc, getDoc, updateDoc, collection, addDoc, runTransaction } from 'firebase/firestore';
import { db } from '../firebase';

export async function getShopItems() {
  const itemsCollection = collection(db, 'items');
  const querySnapshot = await getDocs(itemsCollection);
  return querySnapshot.docs.map(doc => ({ ...doc.data() as Item, id: doc.id }));
}

export async function purchaseItem(userId: string, petId: string, itemId: string) {
  await runTransaction(db, async (transaction) => {
    const userRef = doc(db, 'users', userId);
    const petRef = doc(db, 'pets', petId);
    const itemRef = doc(db, 'items', itemId);

    const userSnapshot = await transaction.get(userRef);
    if (!userSnapshot.exists()) {
      throw new Error('Пользователь не найден');
    }

    const petSnapshot = await transaction.get(petRef);
    if (!petSnapshot.exists()) {
      throw new Error('Питомец не найден');
    }

    const itemSnapshot = await transaction.get(itemRef);
    if (!itemSnapshot.exists()) {
      throw new Error('Предмет не найден');
    }

    const user = userSnapshot.data() as User;
    const item = itemSnapshot.data() as Item;

    if (user.coins < item.price_coins) {
      throw new Error('Недостаточно средств');
    }

    transaction.update(userRef, { coins: user.coins - item.price_coins });
    transaction.update(petRef, { inventory: arrayUnion(itemId) });

    const inventoryCollection = collection(db, 'inventory', petId);
    await addDoc(inventoryCollection, {
      itemId,
      purchased_at: Timestamp.now()
    });
  });
}
