import React, { useEffect } from 'react';
import { PetDisplay } from '../components/PetDisplay';
import { getPet, updatePetStats } from '../lib/firebase/pets';
import { decayStats } from '../lib/petLogic';

interface DashboardPageProps {
  params: { petId: string };
}

const DashboardPage: React.FC<DashboardPageProps> = ({ params }) => {
  const [pet, setPet] = React.useState<Pet | null>(null);

  useEffect(() => {
    const fetchPet = async () => {
      try {
        const fetchedPet = await getPet(params.petId);
        setPet(fetchedPet);
      } catch (error) {
        console.error('Ошибка при получении питомца:', error);
      }
    };

    fetchPet();

    const interval = setInterval(async () => {
      if (pet) {
        const updatedPet = decayStats(pet);
        await updatePetStats(params.petId, updatedPet);
        setPet(updatedPet);
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [params.petId, pet]);

  if (!pet) {
    return <div>Загрузка...</div>;
  }

  return (
    <div>
      <h1>Питомец</h1>
      <PetDisplay pet={pet} />
      {/* Добавь кнопку "Feed" */}
      <button onClick={() => {
        updatePetStats(params.petId, { hunger: pet.hunger + 20 });
      }}>Покормить</button>
    </div>
  );
};

export default DashboardPage;
