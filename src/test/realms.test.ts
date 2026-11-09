import { describe, expect, it } from "vitest";

import { ALL_DUNGEONS, MAX_LEVEL, WORLDS, getDifficulty } from "@/lib/realms";

describe("Retro Realms world data", () => {
  it("has 10 areas and 12 dungeons", () => {
    expect(WORLDS).toHaveLength(10);
    expect(ALL_DUNGEONS).toHaveLength(12);
  });

  it("starts in a village area with two dungeons", () => {
    expect(WORLDS[0].towns).toContain("Emberbrook Village");
    expect(WORLDS[0].dungeons).toHaveLength(2);
  });

  it("caps levels at 2000 with the hardest dungeon at 1200", () => {
    expect(MAX_LEVEL).toBe(2000);
    expect(Math.max(...ALL_DUNGEONS.map((d) => d.level))).toBe(1200);
  });

  it("rates a level 500 dungeon as Suicidal for a level 20 player", () => {
    expect(getDifficulty(500, 20).name).toBe("Suicidal");
  });

  it("rates a dungeon at your own level as Fair", () => {
    expect(getDifficulty(300, 300).name).toBe("Fair");
  });
});
