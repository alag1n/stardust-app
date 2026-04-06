import React, { useState } from 'react';
import { Item } from '../types/item';
import { getShopItems, purchaseItem } from '../lib/firebase/shop';

interface ShopProps {
  petId: string;
}

const Shop: React.FC<ShopProps> = ({ petId }) => {
  const [items, setItems] = useState<Item[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchItems = async () => {
      try {
        const fetchedItems = await getShopItems();
        setItems(fetchedItems);
      } catch (error) {
        console.error('Ошибка при получении товаров:', error);
      }
    };

    fetchItems();
  }, []);

  const handlePurchaseItem = async (itemId: string) => {
    setError(null);
    try {
      await purchaseItem('user_id', petId, itemId); // Замените 'user_id' на реальный ID пользователя
    } catch (error) {
      setError(error.message);
    }
  };

  return (
    <div>
      <h2>Магазин</h2>
      {items.map(item => (
        <div key={item.id} className="bg-white p-4 rounded shadow mb-2">
          <h3>{item.name}</h3>
          <p>Тип: {item.type}</p>
          <p>Цена: {item.price_coins} монет</p>
          <button onClick={() => handlePurchaseItem(item.id)} className="bg-blue-500 text-white px-4 py-2 rounded">
            Купить
          </button>
          {error && <p className="text-red-500">{error}</p>}
        </div>
      ))}
    </div>
  );
};

export default Shop;
