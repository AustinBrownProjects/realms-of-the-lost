import data from "@/data/realms.json";

// Exported from the game's Shared Lua modules (Worlds, Dungeons, Progression).
export type Dungeon = {
  id: string;
  name: string;
  level: number;
  secret: boolean;
  description: string;
};

export type World = {
  id: string;
  name: string;
  order: number;
  biome: string;
  min: number;
  max: number;
  gx: number;
  gz: number;
  color: string;
  description: string;
  towns: string[];
  dungeons: Dungeon[];
};

export type Difficulty = {
  name: string;
  color: string;
  warning: string;
  maxRatio: number;
};

export const MAX_LEVEL: number = data.maxLevel;
export const WORLDS: World[] = [...(data.worlds as World[])].sort((a, b) => a.order - b.order);
export const DIFFICULTIES: Difficulty[] = data.difficulties as Difficulty[];

/** Same formula as Progression.GetDifficulty in the game. */
export function getDifficulty(targetLevel: number, playerLevel: number): Difficulty {
  const ratio = (targetLevel + 10) / (Math.max(1, playerLevel) + 10);
  const fallback = DIFFICULTIES[DIFFICULTIES.length - 1] as Difficulty;
  return DIFFICULTIES.find((d) => ratio <= d.maxRatio) ?? fallback;
}

export const ALL_DUNGEONS = WORLDS.flatMap((w) => w.dungeons);
export const TOWN_COUNT = WORLDS.reduce((n, w) => n + w.towns.length, 0);
