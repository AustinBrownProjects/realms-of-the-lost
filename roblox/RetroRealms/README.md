# Retro Realms - Roblox Studio guide

A retro, semi open world dungeon RPG. 10 areas of the world, 15 towns, 12
dungeons, levels 1 to 2000. Nothing is locked by level: every area and
dungeon shows a recommended level and a colour-coded danger rating
(Trivial, Easy, Fair, Hard, Deadly, Suicidal), and the maths makes it so a
level 20 player who walks into a level 500 dungeon dies almost instantly.

## 1. Open it

1. Open **RetroRealms.rbxl** in Roblox Studio (double-click it, or
   File > Open from File).
2. Press **Play** (F5). You spawn in Emberbrook Village holding a sword.

## 2. Turn on saving (one time)

1. File > **Publish to Roblox** and create a new experience.
2. Home > **Game Settings** > Security > turn on
   **Enable Studio Access to API Services**. Save.

Without this the game still runs in Studio, but progress isn't saved
between tests. Live servers always save.

## 3. Publish

1. Game Settings > **Permissions** > set the experience to **Public**.
2. Add an icon, thumbnails and a description on the Creator Hub.
3. File > Publish to Roblox again after every change.

## How to play

- **Attack:** click (or tap) while holding the sword.
- **Map / fast travel:** press **M** or the MAP button. Towns you have
  visited can be travelled to.
- **Respawn:** you respawn at the last town you walked into.
- **Dungeons:** walk up to a glowing doorway and hold E. A window shows how
  dangerous it is before you enter. Friends who enter within 15 seconds join
  your run. Beat the boss for a big reward, then use the gold portal.

## Test commands (Studio and the experience owner only)

| Command | What it does |
| --- | --- |
| `/dev` | list commands |
| `/setlevel 500` | set your level |
| `/addxp 100000` | give XP |
| `/gold 5000` | give gold |
| `/heal` | full heal |
| `/tp desert` | teleport to an area, town or dungeon by name |
| `/resetme` | wipe your own progress |

To let a friend use them in live servers, add their UserId to
`DevCommandUserIds` in ReplicatedStorage > Shared > GameConfig.

## Where things are

| In Studio | What it is |
| --- | --- |
| ReplicatedStorage > Shared > **GameConfig** | all the main numbers (max level, cooldowns, damage, rewards) |
| ReplicatedStorage > Shared > **Worlds** | the 10 areas: level ranges, towns, monsters, dungeons |
| ReplicatedStorage > Shared > **Dungeons** | the 12 dungeons: recommended level, rooms, boss |
| ReplicatedStorage > Shared > **Monsters** | every monster and boss: size, colour, strength |
| ReplicatedStorage > Shared > **Progression** | XP curve, damage maths, danger ratings |
| ServerScriptService > **GameServer** | everything the server runs |
| StarterPlayer > StarterPlayerScripts > **Client** | the player's screen, map, nameplates, attacking |
| Workspace > **Map** | the ground, houses, trees, cliffs (edit freely) |
| Workspace > **Towns** | one SpawnLocation per town (attributes TownName, WorldId) |
| Workspace > **DungeonEntrances** | one glowing part per dungeon (attribute DungeonId, front face points outward) |
| Workspace > **MonsterSpawns** | invisible spawn points (attributes MonsterId, MinLevel, MaxLevel, MaxAlive, Radius) |
| Workspace > **WorldZones** | one invisible box per area, used to detect which area you're in |

## Making it your own

- **Replace a monster's look:** put a model named after the monster's Id
  (for example `Slime`) in ServerStorage > **MonsterModels**. It needs a
  Humanoid and a HumanoidRootPart.
- **Hand-build a dungeon:** put a model named after the dungeon's Id in
  ServerStorage > **DungeonTemplates** with parts named `Start` and
  `BossSpawn`, an optional `Exit`, and a folder named `MobSpawns`
  containing parts where monsters appear.
- **Move or rebuild the map:** edit anything in Workspace > Map. Keep the
  Towns, DungeonEntrances, MonsterSpawns and WorldZones folders. If you
  delete WorldZones, a brand-new placeholder map is generated when the game
  starts.

## For coders (optional)

The source is also laid out for [Rojo](https://rojo.space):
`rojo serve` from this folder syncs the scripts into Studio.
`lune run tests/rules.luau` checks the game's design rules.
