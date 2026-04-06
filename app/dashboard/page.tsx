import React, { useEffect } from 'react';
import { PetDisplay } from '../components/PetDisplay';
import { getPet, updatePetStats } from '../lib/firebase/pets';
import { decayStats } from '../lib/petLogic';
import { getUserTasks } from '../lib/firebase/tasks';
import { Shop } from '../components/Shop';
import { Inventory } from '../components/Inventory';

interface DashboardPageProps {
  params: { petId: string };
}

const DashboardPage: React.FC<DashboardPageProps> = ({ params }) => {
  const [pet, setPet] = React.useState<Pet | null>(null);
  const [tasks, setTasks] = React.useState<Task[]>([]);
  const [userCoins, setUserCoins] = React.useState<number>(0);
  const [userEnergy, setUserEnergy] = React.useState<number>(0);

  useEffect(() => {
    const fetchPet = async () => {
      try {
        const fetchedPet = await getPet(params.petId);
        setPet(fetchedPet);
      } catch (error) {
        console.error('Ошибка при получении питомца:', error);
      }
    };

    const fetchTasks = async () => {
      try {
        const fetchedTasks = await getUserTasks('user_id'); // Замените 'user_id' на реальный ID пользователя
        setTasks(fetchedTasks);
      } catch (error) {
        console.error('Ошибка при получении заданий:', error);
      }
    };

    fetchPet();
    fetchTasks();

    const interval = setInterval(async () => {
      if (pet) {
        const updatedPet = decayStats(pet);
        await updatePetStats(params.petId, updatedPet);
        setPet(updatedPet);
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [params.petId, pet]);

  useEffect(() => {
    // Обновление баланса после выполнения задания
    const fetchUserBalance = async () => {
      try {
        const userRef = doc(db, 'users', 'user_id'); // Замените 'user_id' на реальный ID пользователя
        const userSnapshot = await getDoc(userRef);
        if (userSnapshot.exists()) {
          const user = userSnapshot.data() as User;
          setUserCoins(user.coins);
          setUserEnergy(user.energy);
        }
      } catch (error) {
        console.error('Ошибка при получении баланса:', error);
      }
    };

    fetchUserBalance();
  }, []);

  return (
    <div>
      <h1>Питомец</h1>
      <PetDisplay pet={pet} />
      {/* Добавь кнопку "Feed" */}
      <button onClick={() => {
        updatePetStats(params.petId, { hunger: pet.hunger + 20 });
      }}>Покормить</button>
      <div className="mt-4">
        <h2>Баланс</h2>
        <p>Монеты: {userCoins}</p>
        <p>Энергия: {userEnergy}</p>
      </div>
      <div className="mt-4">
        <h2>Задания</h2>
        <TaskList tasks={tasks} />
      </div>
      <div className="mt-4">
        <h2>Магазин</h2>
        <Shop petId={params.petId} />
      </div>
      <div className="mt-4">
        <h2>Инвентарь</h2>
        <Inventory petId={params.petId} />
      </div>
    </div>
  );
};

export default DashboardPage;
