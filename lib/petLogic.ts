import { Pet } from '../types/pet';

export function decayStats(pet: Pet): Pet {
  const decayRate = 0.1;
  return {
    ...pet,
    hunger: Math.max(0, pet.hunger - decayRate),
    energy: Math.max(0, pet.energy - decayRate),
    mood: Math.max(0, pet.mood - decayRate),
  };
}
