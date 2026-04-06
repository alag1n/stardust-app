import React, { useState } from 'react';
import { Item } from '../types/item';
import { useItem } from '../lib/petLogic';

interface InventoryProps {
  petId: string;
}

const Inventory: React.FC<InventoryProps> = ({ petId }) => {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchItems = async () => {
      try {
        const inventoryCollection = collection(db, 'inventory', petId);
        const querySnapshot = await getDocs(inventoryCollection);
        const fetchedItems = querySnapshot.docs.map(doc => ({ ...doc.data() as Item, id: doc.id }));
        setItems(fetchedItems);
      } catch (error) {
        console.error('Ошибка при получении инвентаря:', error);
      }
    };

    fetchItems();
  }, []);

  const handleUseItem = async (itemId: string) => {
    setError(null);
    try {
      // Здесь нужно реализовать логику использования предмета
      // Например, применить эффект к питомцу и обновить Firestore
      // Для этого можно использовать функцию useItem из lib/petLogic.ts
      // Пример:
      const updatedPet = useItem(pet, item);
      await updateDoc(doc(db, 'pets', petId), { ...updatedPet });
    } catch (error) {
      setError(error.message);
    }
  };

  return (
    <div>
      <h2>Инвентарь</h2>
      {items.map(item => (
        <div key={item.id} className="bg-white p-4 rounded shadow mb-2">
          <h3>{item.name}</h3>
          <p>Тип: {item.type}</p>
          <button onClick={() => handleUseItem(item.id)} className="bg-blue-500 text-white px-4 py-2 rounded">
            Использовать
          </button>
          {error && <p className="text-red-500">{error}</p>}
        </div>
      ))}
    </div>
  );
};

export default Inventory;
