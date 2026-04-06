import React from 'react';
import { Pet } from '../types/pet';

interface PetDisplayProps {
  pet: Pet;
}

const PetDisplay: React.FC<PetDisplayProps> = ({ pet }) => {
  return (
    <div className="bg-white p-4 rounded shadow">
      <h2>{pet.name}</h2>
      <p>Уровень: {pet.level}</p>
      <p>XP: {pet.xp}</p>
      <progress value={pet.xp} max={100}></progress>
      <p>Голод: {pet.hunger}</p>
      <p>Энергия: {pet.energy}</p>
      <p>Настроение: {pet.mood}</p>
    </div>
  );
};

export default PetDisplay;
