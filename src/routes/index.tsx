import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { Download, Map as MapIcon, Swords, Skull, Upload, Settings } from "lucide-react";

import worldMap from "@/assets/world-map.png";
import {
  ALL_DUNGEONS,
  DIFFICULTIES,
  MAX_LEVEL,
  TOWN_COUNT,
  WORLDS,
  getDifficulty,
} from "@/lib/realms";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Retro Realms — Roblox dungeon RPG starter game" },
      {
        name: "description",
        content:
          "Download Retro Realms: a ready-to-publish retro dungeon RPG for Roblox Studio with 10 areas, 12 dungeons and no level locks.",
      },
      { property: "og:title", content: "Retro Realms — Roblox dungeon RPG starter game" },
      {
        property: "og:description",
        content: "10 areas, 15 towns, 12 dungeons and levels up to 2000. Open it in Roblox Studio and publish.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Index,
});

// Map image covers world x -550..2550 and z -550..3550 (1000-stud tiles)
const tilePos = (gx: number, gz: number) => ({
  left: `${((gx * 1000 + 550) / 3100) * 100}%`,
  top: `${((gz * 1000 + 550) / 4100) * 100}%`,
});

function PixelButton({
  href,
  children,
  variant = "primary",
}: {
  href: string;
  children: React.ReactNode;
  variant?: "primary" | "secondary";
}) {
  const styles =
    variant === "primary"
      ? "bg-primary text-primary-foreground"
      : "bg-secondary text-secondary-foreground border-2 border-border";
  return (
    <a
      href={href}
      download
      className={`${styles} inline-flex items-center gap-3 px-5 py-4 font-pixel text-xs uppercase shadow-pixel transition-transform hover:-translate-x-0.5 hover:-translate-y-0.5 active:translate-x-0.5 active:translate-y-0.5`}
    >
      {children}
    </a>
  );
}

function SectionTitle({ kicker, title }: { kicker: string; title: string }) {
  return (
    <div className="mb-8">
      <p className="font-pixel text-[10px] uppercase tracking-widest text-accent">{kicker}</p>
      <h2 className="mt-3 font-pixel text-lg leading-relaxed text-primary sm:text-2xl">{title}</h2>
    </div>
  );
}

function Index() {
  const [level, setLevel] = useState(20);

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="border-b-4 border-border bg-card">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-4">
          <span className="font-pixel text-sm text-primary">RETRO REALMS</span>
          <span className="hidden text-muted-foreground sm:inline">A Roblox Studio starter game</span>
        </div>
      </header>

      <main>
        {/* Hero */}
        <section className="mx-auto grid max-w-6xl gap-10 px-5 py-14 lg:grid-cols-[1.1fr_1fr]">
          <div>
            <p className="font-pixel text-[10px] uppercase tracking-widest text-accent">
              Ready to publish · bare bones edition
            </p>
            <h1 className="mt-5 font-pixel text-2xl leading-relaxed text-primary sm:text-4xl sm:leading-snug">
              Ten realms. Twelve dungeons. No level locks.
            </h1>
            <p className="mt-6 max-w-xl text-2xl text-foreground">
              Start in Emberbrook Village with a sword and two beginner dungeons. Walk anywhere you like — every area
              and dungeon tells you how dangerous it is, and a level 20 hero who strolls into a level 500 dungeon won't
              last a second.
            </p>
            <div className="mt-8 flex flex-wrap gap-4">
              <PixelButton href="/downloads/RetroRealms.rbxl">
                <Download className="h-4 w-4" /> Place file (.rbxl)
              </PixelButton>
              <PixelButton href="/downloads/RetroRealms.zip" variant="secondary">
                <Download className="h-4 w-4" /> Full package (.zip)
              </PixelButton>
            </div>
            <dl className="mt-10 grid grid-cols-2 gap-4 sm:grid-cols-4">
              {[
                ["Areas", WORLDS.length],
                ["Towns", TOWN_COUNT],
                ["Dungeons", ALL_DUNGEONS.length],
                ["Max level", MAX_LEVEL],
              ].map(([label, value]) => (
                <div key={label} className="border-2 border-border bg-card p-3 shadow-pixel">
                  <dt className="text-muted-foreground">{label}</dt>
                  <dd className="mt-1 font-pixel text-base text-primary">{value}</dd>
                </div>
              ))}
            </dl>
          </div>

          <figure className="relative mx-auto w-full max-w-md border-4 border-border bg-card p-2 shadow-glow">
            <div className="relative">
              <img
                src={worldMap}
                alt="Top-down map of the ten areas of Retro Realms"
                className="pixelated block h-auto w-full"
                width={1550}
                height={2050}
              />
              {WORLDS.map((w) => (
                <div
                  key={w.id}
                  className="pointer-events-none absolute -translate-x-1/2 -translate-y-1/2 text-center"
                  style={tilePos(w.gx, w.gz)}
                >
                  <span className="block whitespace-nowrap bg-background/80 px-1.5 py-0.5 font-pixel text-[8px] text-foreground sm:text-[9px]">
                    {w.order}. {w.name}
                  </span>
                </div>
              ))}
            </div>
            <figcaption className="mt-2 px-1 text-lg text-muted-foreground">
              Gold squares are towns. Glowing squares are dungeon doors.
            </figcaption>
          </figure>
        </section>

        {/* Steps */}
        <section className="border-y-4 border-border bg-card">
          <div className="mx-auto max-w-6xl px-5 py-14">
            <SectionTitle kicker="Get it live" title="Publish in three steps" />
            <ol className="grid gap-6 md:grid-cols-3">
              {[
                {
                  icon: MapIcon,
                  title: "Open",
                  body: "Double-click RetroRealms.rbxl to open it in Roblox Studio. Press Play to spawn in the village.",
                },
                {
                  icon: Settings,
                  title: "Turn on saving",
                  body: "File › Publish to Roblox, then Game Settings › Security › Enable Studio Access to API Services.",
                },
                {
                  icon: Upload,
                  title: "Go public",
                  body: "Game Settings › Permissions › Public. Add an icon and thumbnails on the Creator Hub.",
                },
              ].map((step, i) => (
                <li key={step.title} className="border-2 border-border bg-background p-5 shadow-pixel">
                  <div className="flex items-center gap-3">
                    <span className="font-pixel text-xl text-accent">{i + 1}</span>
                    <step.icon className="h-5 w-5 text-primary" />
                    <h3 className="font-pixel text-xs uppercase text-primary">{step.title}</h3>
                  </div>
                  <p className="mt-4 text-xl">{step.body}</p>
                </li>
              ))}
            </ol>
          </div>
        </section>

        {/* Realms */}
        <section className="mx-auto max-w-6xl px-5 py-14">
          <SectionTitle kicker="The world" title="The ten realms" />
          <div className="mb-8 border-2 border-border bg-card p-5 shadow-pixel">
            <label htmlFor="level" className="flex flex-wrap items-center justify-between gap-2">
              <span className="font-pixel text-xs uppercase text-primary">Your level: {level}</span>
              <span className="text-muted-foreground">Drag to see how dangerous each dungeon looks to you</span>
            </label>
            <input
              id="level"
              type="range"
              min={1}
              max={MAX_LEVEL}
              value={level}
              onChange={(e) => setLevel(Number(e.target.value))}
              className="mt-4 w-full accent-primary"
            />
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            {WORLDS.map((w) => {
              const areaRating = getDifficulty(w.min, level);
              return (
                <article key={w.id} className="border-2 border-border bg-card shadow-pixel">
                  <div className="h-3" style={{ backgroundColor: w.color }} />
                  <div className="p-5">
                    <div className="flex flex-wrap items-baseline justify-between gap-2">
                      <h3 className="font-pixel text-sm leading-relaxed text-primary">
                        {w.order}. {w.name}
                      </h3>
                      <span className="font-pixel text-[10px]" style={{ color: areaRating.color }}>
                        LV {w.min}–{w.max}
                      </span>
                    </div>
                    <p className="mt-3 text-xl">{w.description}</p>
                    <p className="mt-3 text-muted-foreground">
                      {w.towns.length > 1 ? "Towns" : "Town"}: {w.towns.join(", ")}
                    </p>
                    <ul className="mt-4 space-y-2">
                      {w.dungeons.map((d) => {
                        const rating = getDifficulty(d.level, level);
                        return (
                          <li
                            key={d.id}
                            className="flex flex-wrap items-center justify-between gap-2 border-t-2 border-border pt-2"
                          >
                            <span className="flex items-center gap-2">
                              <Swords className="h-4 w-4 text-accent" />
                              {d.name}
                              {d.secret && (
                                <span className="bg-accent px-1.5 font-pixel text-[8px] uppercase text-accent-foreground">
                                  Secret
                                </span>
                              )}
                            </span>
                            <span className="font-pixel text-[10px]" style={{ color: rating.color }}>
                              LV {d.level} · {rating.name}
                            </span>
                          </li>
                        );
                      })}
                    </ul>
                  </div>
                </article>
              );
            })}
          </div>
        </section>

        {/* Ratings */}
        <section className="border-y-4 border-border bg-card">
          <div className="mx-auto max-w-6xl px-5 py-14">
            <SectionTitle kicker="Nothing is locked" title="Danger ratings" />
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {DIFFICULTIES.map((d) => (
                <div key={d.name} className="flex items-start gap-3 border-2 border-border bg-background p-4">
                  <Skull className="mt-1 h-5 w-5 shrink-0" style={{ color: d.color }} />
                  <div>
                    <p className="font-pixel text-xs uppercase" style={{ color: d.color }}>
                      {d.name}
                    </p>
                    <p className="mt-2 text-lg">{d.warning}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Controls */}
        <section className="mx-auto grid max-w-6xl gap-10 px-5 py-14 md:grid-cols-2">
          <div>
            <SectionTitle kicker="Playing" title="Controls" />
            <ul className="space-y-3 text-xl">
              <li><span className="font-pixel text-xs text-primary">Click / tap</span> — swing your sword</li>
              <li><span className="font-pixel text-xs text-primary">M</span> — world map and fast travel</li>
              <li><span className="font-pixel text-xs text-primary">Hold E</span> — enter a dungeon door</li>
              <li>Friends who enter within 15 seconds join your dungeon run.</li>
              <li>You respawn at the last town you walked into.</li>
            </ul>
          </div>
          <div>
            <SectionTitle kicker="Testing" title="Chat commands" />
            <p className="mb-3 text-muted-foreground">Work in Studio and for the game's owner.</p>
            <ul className="space-y-2 font-pixel text-[10px] leading-loose">
              {[
                ["/setlevel 500", "set your level"],
                ["/addxp 100000", "give XP"],
                ["/gold 5000", "give gold"],
                ["/tp desert", "teleport by name"],
                ["/heal", "full heal"],
                ["/resetme", "wipe your progress"],
              ].map(([cmd, what]) => (
                <li key={cmd} className="flex justify-between gap-3 border-b-2 border-border pb-2">
                  <span className="text-primary">{cmd}</span>
                  <span className="text-muted-foreground">{what}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>
      </main>

      <footer className="border-t-4 border-border bg-card">
        <div className="mx-auto max-w-6xl px-5 py-6 text-muted-foreground">
          Retro Realms · placeholder blocky art — swap in your own models any time.
        </div>
      </footer>
    </div>
  );
}
