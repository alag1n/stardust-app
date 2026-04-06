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

export function useItem(pet: Pet, item: Item): Pet {
  const { stat, value } = item.effect;
  return {
    ...pet,
    [stat]: Math.min(100, pet[stat] + value) // Предполагается, что статы ограничены от 0 до 100
  };
}
