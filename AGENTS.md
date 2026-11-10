<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.

## What Lovable manages

Rules outside this block are the project's own. Change the pieces below in
Lovable, not by hand. With the [Lovable MCP](https://mcp.lovable.dev)
connected, `send_message` asks Lovable to do it; otherwise ask the user to
use the editor.

- **Database.** Do not add or edit `supabase/migrations/` or `drizzle/`.
  Ask Lovable to change the schema.
- **Generated files.** Do not edit a file whose header says it is automatically
  generated.
- **AI gateway.** Keep model calls on Lovable's gateway, and keep
  `LOVABLE_API_KEY` out of browser code.
- **Connectors.** Lovable provides native connectors. `list_connectors` shows
  which are enabled; `add_connector` only returns the dashboard link. When a
  connector is enabled, calls go through the connector gateway and need
  `LOVABLE_API_KEY`. When Lovable does not provide one, users can bring their
  own key and store it in Secrets.
- **Secrets.** Lovable manages them. Do not put secret values in the repo.
<!-- LOVABLE:END -->

## Project rules

- The real product is the Roblox game in `roblox/RetroRealms` (Luau, Rojo layout); the web app is only a companion download page. Why: the user builds in Roblox Studio.
- Game tuning lives in `ReplicatedStorage/Shared` modules (GameConfig, Worlds, Dungeons, Monsters, Progression); services read from them instead of hardcoding numbers. Why: one place to rebalance.
- Nothing is level-gated in code; difficulty comes only from Progression maths and the shown ratings. Why: core design rule.
- After changing game scripts, rebuild the place with `rojo build` + `lune run tools/bake.luau` (bakes the greybox map into Workspace), re-run `lune run tests/rules.luau`, re-export `src/data/realms.json`, and refresh `public/downloads`. Why: downloads must match source.
- The bake harness overrides Lune's `CFrame.lookAt` (Lune 0.10 returns a mirrored rotation). Why: otherwise baked roads/doors face the wrong way.
