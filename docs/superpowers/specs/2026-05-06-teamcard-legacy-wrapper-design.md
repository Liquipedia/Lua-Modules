# TeamCard → TeamParticipants Legacy Wrapper

**Date:** 2026-05-06
**Status:** Design (awaiting user review)
**Ticket:** https://gitlab.com/teamliquid-dev/liquipedia/issue-bucket/-/work_items/1100

## Goal

Replace the old `Module:TeamCard` rendering with `Module:TeamParticipants/Controller` on existing tournament pages, without touching the page wikitext. The conversion is done by a Legacy wrapper module that intercepts the `{{TeamCard columns start}}` / `{{TeamCard}}` / `{{TeamCard columns end}}` template invocations, reshapes their args into TeamParticipants input, and renders.

Rollout is wiki-by-wiki, starting with ArenaFPS. LPDB storage is delegated to TeamParticipants. The record shape is intentionally close to TeamCard's writes (legacy participant fields via `Opponent.toLegacyParticipantData`, qualifier fields, individualprizemoney, opponentaliases), but it is **not byte-for-byte identical**. Known deltas are documented in Section 5 and must be accepted or audited during rollout.

**Subst is not used initially.** A subst-based Lua wrapper was discussed (hjpalpha); the team's call (Rathoz) is to land the live wrapper first so we can iterate on bugs in the mappings, then look at subst afterwards.

**Out of reach for this wrapper:** StarCraft, StarCraft 2, and Stormgate use TeamCard-like layouts that aren't compatible with this wrapper (different param model). Those wikis stay on their existing modules.

## Out of scope

- Per-wiki bot-edit work to insert `{{TeamCard columns start}}` / `{{TeamCard columns end}}` around naked `{{TeamCard}}` runs. The wrapper assumes columns markers are always present. (hjpalpha sketched a regex pre-pass: rewrite `{{Box | start}}` / `{{Box | break}}` / `{{Box | end}}` triples wrapping `{{TeamCard}}` calls into `{{TeamCard columns start}}` / `{{TeamCard columns end}}` shape — same idea applied to other naked TC layouts.)
- The on-wiki template edits themselves (`Template:TeamCard*`). Those happen at deploy time.
- Per-card `disable_storage` / `nostorage` — TC's heading also doesn't actually use these flags (per Rathoz). They live only on individual `{{TeamCard}}` calls, which the wrapper ignores. If we ever need per-card opt-out, that requires extending TP; revisit then.
- Per-card `lpdb_prefix` — old TC supported this to disambiguate same-team records on a single page (`ranking_<prefix>_<team>`). TP doesn't. To find affected pages before rollout, **add a tracking category to the old `Module:TeamCard`** when `args.lpdb_prefix` is set, so we can audit the few pages that use it before migrating the affected wikis.
- StarCraft / StarCraft 2 / Stormgate wikis (see Goal). Their TC variants aren't compatible.
- Adding `joindate`/`leavedate` to TP's player input parser and `setPageVars`. There's an in-flight TP PR doing this, which we assume lands before this wrapper ships; the wrapper just passes the values through.

## Architecture

```
Wiki templates (on-wiki, edited at deploy):
  Template:TeamCard columns start  → invoke Module:Template fn=stashArgs namespace=LegacyTeamCard
  Template:TeamCard                → invoke Module:Template fn=stashArgs namespace=LegacyTeamCard
  Template:TeamCard columns end    → invoke Module:TeamCard/Legacy/Custom fn=run (wikis with a Custom file)
                                    OR Module:TeamCard/Legacy fn=run (wikis without one — most wikis)

In-repo Lua modules (new):
  Module:TeamCard/Legacy            (lua/wikis/commons/TeamCard/Legacy.lua)
  Module:TeamCard/Legacy/Custom     (lua/wikis/<wiki>/TeamCard/Legacy/Custom.lua, OPTIONAL per wiki)

In-repo Lua modules (existing, reused):
  Module:TeamParticipants/Controller — render and store via TP.fromTemplate-equivalent path
  Module:TeamParticipants/Repository — TP's existing storage; near-compatible with TC LPDB writes plus known deltas in Section 5
  Module:Template                   — stashArgs/retrieveReturnValues
```

The flow on `{{TeamCard columns end}}` invocation:

1. `{{TeamCard columns end}}` invokes either `Module:TeamCard/Legacy/Custom|fn=run` (wikis that have a Custom file) or `Module:TeamCard/Legacy|fn=run` directly (wikis that don't). Most wikis don't need a Custom file — see Section 1 and Section 7.
2. `Legacy.run` retrieves all stashed args via `Template.retrieveReturnValues('LegacyTeamCard')`.
3. Stash entries are partitioned by their `__source` sentinel (`toggle`, `header`, `card` — see Section 2): zero-or-more toggles, one header/block marker, N cards.
4. Toggle + block args fold into TP top-level args (`minimumplayers`, `showplayerinfo`, `note` rendering); biz-logic flags from the wiki template body (`subdnpdefault`, `formerdnpdefault`, `noVarDefault`, etc.) are read off the per-card stash entries and applied during mapping. Per-card `import=false` is set on each opponent, overriding any stashed `import` value. In mainspace the wrapper leaves `store` unset so TP's existing SaveLpdb handling applies; outside mainspace it preserves old TC behavior by forcing storage off (or by using an equivalent render path that skips TP storage outside mainspace).
5. Each card is mapped into a TP `Opponent` arg shape (Sections 3 + 4 below).
6. The collected TP args are passed into a render path equivalent to `TeamParticipantsController.fromTemplate`, which itself calls `TeamParticipantsRepository.save` (storing in a TC-compatible shape) and `TeamParticipantsRepository.setPageVars` (defining the per-team / per-player wiki vars).

## Section 1 — Module layout & wiki templates

**`Module:TeamCard/Legacy`** (commons): the mapping pipeline as small functions.
Exports:
- `LegacyTeamCard.run(opts)` — entry point. `opts` is an optional table; the only currently-supported key is `preprocessCard` (see below). If `opts` is omitted, identity preprocessing is used.
- `LegacyTeamCard.mapHeader(header) -> tpHeaderArgs` (currently block metadata / validation only)
- `LegacyTeamCard.mapCard(tcArgs) -> tpOpponentArgs`
- `LegacyTeamCard.mapPlayers(tcArgs) -> personArgs[]`
- `LegacyTeamCard.mapCoaches(tcArgs) -> personArgs[]`
- `LegacyTeamCard.parseQualifier(rawQualifier) -> qualificationStruct`

The wrapper recognizes the wiki-template-body biz-logic args (`defaultRowNumber`, `extraRows`, `subdnpdefault`, `formerdnpdefault`, `t2type`, `t3type`, etc.) and maps them to TP equivalents. Display-only TC options (`sideTabs`, `iconModule`, `coachborder`, `tabsMergeCoaches`, …) are silently dropped.

**`Module:TeamCard/Legacy/Custom`** (OPTIONAL per wiki): only created when a wiki needs Lua-level preprocessing of stashed args. Most wikis don't need one.

The decision tree for whether a wiki needs a Custom file:

- **No Custom file** if the wiki's existing `Template:TeamCard` body uses standard TC args directly (with at most `defaultRowNumber` / `maxPlayers` / `subdnpdefault` / etc. defaults baked in). Just edit the wiki template to invoke `stashArgs`. `Template:TeamCard columns end` invokes `Module:TeamCard/Legacy|fn=run` directly. Examples: ArenaFPS, CS, dota2, LoL, HoK, R6, OW, Valorant.

- **Custom file needed** if the wiki's `Template:TeamCard` does heavy wikitext-level argument aliasing or rewriting (e.g. RocketLeague maps `sub1..3` → `p1..3` with `pos=<abbr>S</abbr>`, `sub4..12` → `s4..12` with `flag/link/result` mirroring, `ex1..7` → `f1..7`). Move the rewriting from the wiki template into Lua. Custom file shape:

```lua
local Lua = require('Module:Lua')
local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local Custom = {}

---@param tcArgs table  -- raw stashed args for one card
---@return table        -- args reshaped into the standard TC param shape (p1..pN, s1..sM, f1..fK, c1..cN, ...)
function Custom.preprocessCard(tcArgs)
    -- e.g. RL: rewrite sub1..3 into p1..3 with status=sub, sub4..12 into s4..12, ex* into f*, etc.
    return tcArgs
end

function Custom.run()
    return LegacyTeamCard.run({ preprocessCard = Custom.preprocessCard })
end

return Custom
```

(Header / toggle preprocessing hooks aren't currently exposed — add `preprocessHeader` / `preprocessToggle` if a real wiki need surfaces.)

**Wiki-side template edits** (out-of-repo, but documented for the rollout):

| Template | Old body | New body |
|---|---|---|
| `Template:TeamCard columns start` | Opens the columns wrapper and defines `TeamCard columns*`, `TeamCard padding`, `TCheight` page vars. | `<div></div>{{#invoke:Lua\|invoke\|module=Template\|fn=stashArgs\|namespace=LegacyTeamCard\|__source=header\|cols={{{cols\|4}}}\|padding={{{padding\|2em}}}\|height={{{height\|}}}}}`. This is block metadata only; `defaultRowNumber` etc. do **not** originate here. |
| `Template:TeamCard` | `{{FRAME_SET_VOLATILE}}` plus `{{#invoke:Lua\|invoke\|module=TeamCard\|fn=draw\|...}}` with wiki-specific defaults. | Keep `{{FRAME_SET_VOLATILE}}`, replace only `module=TeamCard\|fn=draw` with `module=Template\|fn=stashArgs\|namespace=LegacyTeamCard\|__source=card`, and preserve every existing named argument/default from the old invoke (`defaultRowNumber`, `extraRows`, `subdnpdefault`, `formerdnpdefault`, `t2type`, `t3type`, `noVarDefault`, `resolveTeam`, etc.). Example shape: `<div></div>{{FRAME_SET_VOLATILE}}{{#invoke:Lua\|invoke\|module=Template\|fn=stashArgs\|namespace=LegacyTeamCard\|__source=card\|defaultRowNumber=...\|...}}`. |
| `Template:TeamCard columns end` | Closes the wrapper divs, includes `{{FRAME_SET_VOLATILE}}`, clears old TC page vars. | `{{FRAME_SET_VOLATILE}}{{#invoke:Lua\|invoke\|module=TeamCard/Legacy\|fn=run}}` (or `module=TeamCard/Legacy/Custom\|fn=run` on wikis that have a Custom file). The old closing divs and old TC page-var clears are not emitted by the TP render path. |
| `Template:TeamCardToggleButton` | Per-wiki wrapper template that usually calls commons `Template:TeamCardToggleButton/Base`; `/Base` renders the toggle button, optional Player Info button / note, and defines `TCheight` / `tournament_teamplayers_extra`. | Edit the **per-wiki wrapper template** to stash the raw toggle args directly: `<div></div>{{#invoke:Lua\|invoke\|module=Template\|fn=stashArgs\|namespace=LegacyTeamCard\|__source=toggle\|playerinfo={{{playerinfo\|}}}\|p_extra={{{p_extra\|}}}\|note={{{note\|}}}\|tcht={{{tcht\|}}}\|showalltext={{{showalltext\|}}}\|hidealltext={{{hidealltext\|}}}\|height={{{height\|}}}}}`. Do not rely on editing `/Base` alone, because existing per-wiki wrappers forward only subsets of args. The deprecated `Template:PlayerInfoButton` becomes a no-op or is removed once all TC pages have migrated. |

Each `stashArgs` invocation is wrapped in an empty `<div></div>` — without it, MediaWiki's parser inserts a `<br>` for every template call. (Confirmed by both Rathoz and hjpalpha.) Keep `FRAME_SET_VOLATILE` on templates that had it; otherwise identical template calls can be cached/deduplicated before every card has stashed its args. The `Lua|invoke` indirection is intentional and mirrors the existing PrizePool legacy pattern; any dispatch-only keys such as `module` / `fn` are ignored by the wrapper if they appear in the stash.

**Important commons-template constraint:** `Template:TeamCard columns start` and `Template:TeamCard columns end` live on the **commons** wiki. A commons edit affects every wiki simultaneously. To roll out per-wiki without breaking the rest, the practical pattern is:

1. Initially override the templates **locally** on the target wiki (ArenaFPS first) — the local copy shadows commons.
2. Validate on that wiki end-to-end.
3. After several wikis are validated, switch the commons templates to the new bodies and remove the per-wiki local copies one wiki at a time.

## Section 2 — Header/block mapping

Each retrieved stash entry carries an `__source` sentinel set by its originating template:

- `__source = 'toggle'` — from the per-wiki `{{TeamCardToggleButton}}` wrapper. Optional, may appear zero or more times per columns block.
- `__source = 'header'` — from `{{TeamCard columns start}}`. Expected once per block. Despite the historical name, this carries only block-level columns metadata (`cols`, `padding`, `height`); per-wiki TeamCard defaults live on card entries.
- `__source = 'card'` (or absent — defensive default) — from `{{TeamCard}}`. One per card.

Order on the page within a single block: toggle (optional) → header → cards. The wrapper iterates the flushed stash in order, partitions by `__source`, and merges:

**Toggle entries** map into TP top-level args:

| Toggle arg | TP top-level arg | Notes |
|---|---|---|
| `playerinfo=true` | `showplayerinfo=true` | TP's controls strip renders the same Player Info button. |
| `p_extra` (number) | added to `minimumplayers` (sum with `defaultRowNumber`) | Old TC's `tournament_teamplayers_extra` page var extended the player row count; TP's `minimumplayers` is the equivalent. If multiple toggle entries set `p_extra`, the numeric values are summed. |
| `note` (text) | rendered as a sibling div above the TP `CardsGroup` output | No TP arg for this — prepend a styled wrapper div in the rendered output to preserve the visual. If multiple toggles set notes, render all non-empty notes in page order. |
| `tcht`, `showalltext`, `hidealltext`, `height` | dropped | TC-layout-specific styling; TP renders its own controls. |

For multiple toggle entries, `p_extra` and `note` are additive as above; all other recognized toggle args are last-write-wins.

**Card-level template defaults / biz-logic flags** are read from the stashed `card` entries. These are the named args baked into the wiki's `Template:TeamCard` body and must be preserved during the template edit:

| Stashed arg | TP / wrapper behavior | Notes |
|---|---|---|
| `defaultRowNumber` | `minimumplayers` | Closest semantic match. The wrapper reads it from any card entry where it appears; in practice all cards from a wiki template carry the same value. |
| `extraRows` | added to `minimumplayers` | Mirrors old TC's `extraRows`; numeric coercion is explicit. |
| `subdnpdefault` | wrapper-internal flag — see Section 4 | When true, players from the `s*` source group default to `played=false` / `results=false` unless they have `pNplayed=true` / `pNresult=true`. |
| `formerdnpdefault` | wrapper-internal flag, symmetric to `subdnpdefault` for `f*` | Same default-DNP behavior for former-player source groups. |
| `noVarDefault` | wrapper-internal LPDB filter flag — see Section 4 / 5 | Used by Counter-Strike. Preserve old behavior by excluding default-unplayed non-main roster entries from the LPDB player list. |
| `t2type`, `t3type` | wrapper-internal tab/status mapping | Needed for wikis such as R6 that flip the conventional t2/t3 meaning. |
| `resolveTeam` | dropped as an arg; TP resolves teams as part of `Opponent.resolve` | This can differ from old TC templates that did not set `resolveTeam=true`; accepted rollout delta unless a wiki-specific issue appears. |
| `cols`, `padding`, `height` from `header` | currently dropped | TP controls its own grid/layout. The header stash exists mainly to delimit/validate the block. |
| `defaultHeight`, `c2OnNewLine`, `t2title`, `t3title`, `favorDefaultRowNumber`, `maxPlayers`, `maxCoach`, `sidetabs`, `nobgcolor`, `noTeamLinks`, `noQualifierLogos`, `qualifierLogosType`, `iconModule`, `iconGame`, `coachborder`, `tabsMergeCoaches`, `smwMVP` | dropped | TC-display-only or no TP equivalent. The wrapper enumerates stashed `pN` / `cN` keys directly, so `maxPlayers` / `maxCoach` are not iteration bounds. |

Hardcoded by the wrapper:
- `import = false` is set **per card** (not at header level — TP reads `import` off each Opponent), unconditionally overriding any stashed value. Old pages use explicit rosters only.

The wrapper does **not** set a top-level `date`; TP's per-opponent / page-context fallback handles it. TP's date fallback is subtly different from old TC: for cards without explicit `date`, TP prefers `enddate_<opponent>` / `enddate_<opponent>_date` before the contextual/tournament date, whereas old TC used the tournament date chain earlier.

Storage gate:
- In mainspace, the wrapper leaves `store` unset so TP's `Logic.readBoolOrNil(args.store) ~= false and Lpdb.isStorageEnabled()` behavior applies.
- Outside mainspace, the wrapper must force `store=false` or otherwise skip `Repository.save`, preserving old TC's `Namespace.isMain()` gate.

`team` / `teamRR` global page vars are **not** backfilled. Old TC defined them, but a repo-wide grep found no Lua/JS/SCSS reader. If wiki-side modules turn out to depend on them during rollout, add a targeted backfill later.

If the first stash entry doesn't look like a header (no recognizable header keys, presence of `team` key, etc. — which means `columns start` is missing or malformed), the wrapper treats all entries as cards, **adds a tracking category** (e.g. `[[Category:Pages with malformed TeamCard structure]]`), and **emits a warning** in the rendered output. This makes the broken pages findable so they can be fixed; we don't silently fall back, since the missing `columns end` template might also indicate a structural break.

## Section 3 — Per-card → Opponent mapping

For each card stash entry, build one TP `Opponent` arg.

**Team identity:**

| TC | TP | Notes |
|---|---|---|
| `link` (or fallback to `team`) | positional `[1]` (template) | TC's `team` is the display name, `link` is the team template. The wrapper uses `args.link or args.team` for the TP template arg; `link` wins even for `team=TBD`. |
| `team` (display name) | dropped | TP derives display from the team template; no separate display override. |
| `team2`/`team3` set | TP `contenders` (list of team templates) | Maps to TP's `contenders` parsing path: opponent becomes TBD with `potentialQualifiers` populated from **each of `team`, `team2`, `team3`** (so `team` itself is included in the contenders list, not just team2/team3). `link*` values are used as templates when present. |
| `image1`/`imagedark1`/`imagesize` | dropped from rendering | TP uses team templates for images. LPDB `image` / `imagedark` compatibility is called out separately in Section 5. |
| `flag` (header flag) | dropped | Accepted visual delta for nation-team cards; audit sample pages during rollout. |

**Card-level metadata:**

| TC | TP | Notes |
|---|---|---|
| `qualifier` | `qualification.{method,page,url,text,placement}` | See parser rules below. |
| `notes` | appended to `notes` list as `{[1] = value, highlighted=false}` | |
| `inotes` | appended to `notes` list as `{[1] = value, highlighted=false}` | If both `notes` and `inotes` are set, both entries are added to the TP `notes` list. |
| `date` | `date` | |
| `aliases` / `alsoknownas` | `aliases` (semicolon-joined) | Just `aliases`/`alsoknownas` — team2/team3 entries are not folded in here; they go to `contenders` (see Team identity above). If both are set, `alsoknownas` wins (`args.alsoknownas or args.aliases`), matching old TC. |
| `disable_storage`/`nostorage` (per-card) | dropped | Per-card storage opt-out is out-of-scope (header-level only — see Section 5). |
| `placement`, `context`, `preview`, `ref`, `class`, `showroster`, `hideroster` | dropped | Pure formatting / display in old TC; accepted visual/UX delta. |
| `lpdb_prefix` | dropped | TP has no equivalent (out-of-scope per "Out of scope" section). |
| `iconModule`, `iconGame`, `game` | dropped | TC display only. |

**`qualifier` parser rules** (in `LegacyTeamCard.parseQualifier`):

The base link/text extraction is ported from `Module:TeamCard/Qualifier` (currently a wiki-side module — same logic also exists inline in `Module:TeamCard/Storage._parseQualifier` in this repo). It returns `(linkText, linkInternal, linkExternal)`. The wrapper layers method detection on top:

1. **Determine `method`:** if the trimmed raw value matches `Invite`/`Invited` (case-insensitive, optionally with trailing text) → `method = 'invite'`. Otherwise → `method = 'qual'`.
2. **Run the ported parser** to get `(text, internalLink, externalLink)`.
3. **Construct the `qualification` table:**
   - If `internalLink` is set: `{method, type='tournament' or 'internal', page=internalLink, text=text}`. Resolve via `Tournament.getTournament(internalLink)` to decide between `'tournament'` and `'internal'` (TP's parser does this resolution itself, so we can just pass `page` and let TP decide; verify during implementation).
   - Else if `externalLink` is set: `{method, type='external', url=externalLink, text=text}`.
   - Else: `{method, type='other', text=text}`.

Edge: TC's `qualifier=Invited` (no link) → `{method='invite', type='other', text='Invited'}`. TC's `qualifier=[[X/Qualifier|Qualifier]]` → `{method='qual', type='tournament' (if X is a tournament), page=X, text='Qualifier'}`.

## Section 4 — Players & coaches mapping

Old TC has three sources of players (`p*`, `s*`, `f*`) plus optional manual `t2*`/`t3*` tabs. New TP is one flat `players` list with `status` and `type` fields.

The wrapper reads from the **stashed args** (the user's input), not from TC's mutated post-`_parseArgs` shape. This sidesteps the `s*`-into-`t2*` rewrite logic in old TC.

**Player mapping** (per `pN`, `sN`, `fN`, `t2pN`, `t3pN`):

| TC param | TP `Person` field | Notes |
|---|---|---|
| `pN` (display) | positional `[1]` | |
| `pNlink` | `link` | |
| `pNflag_o` / `pNflag` | `flag` | TP has no `flag_o` field. The wrapper picks `pNflag_o or pNflag` and writes the result to TP's single `flag` field. |
| `pNteam` | `team` | Per-player team override. |
| `pNid` | `id` | TP's `Opponent.readSinglePlayerArgs` accepts this as `apiId`. Old TC did not preserve it consistently, but mapping it is harmless and avoids silent drops. |
| `pNfaction` / `pNrace` | `faction` | |
| `pNdnp` (truthy) | `played = false` | `dnp` wins over `played`/`result` if both set. |
| `pNplayed` / `pNresult` | `played` (boolean) | Also leave `results` unset unless explicitly needed; TP defaults `results = played`, which is what filters LPDB player inclusion. |
| `pNleave` (truthy) | `status = former` | |
| `pNsub` (truthy) | `status = sub` | |
| Source group `sN` | `status = sub` | Same as `pNsub`. |
| Source group `fN` | `status = former` | |
| `pNpos` | `role` | Passed through; TP's `RoleUtil.readRoleArgs` normalizes it. If a wiki ends up needing a numeric→role mapping (historically only dota2), that's done in the optional `preprocessCard` hook — see Section 7. |
| `pNwins` + `pNwinsc` | `trophies` | Sum of both — TC displayed them as two trophy icons (won-as-player + won-as-coach), TP collapses to a single trophy count. |
| `pNjoindate` | `joindate` | Pass-through. Assumes the in-flight TP PR adding `joindate`/`leavedate` to player input has landed before this wrapper ships. |
| `pNleavedate` | `leavedate` | Pass-through, same assumption as above. |
| `pNpreview` | dropped | In-card preview link; no TP equivalent. |

**Coach mapping** (per `cN`, `scN`, `fcN`, `t2cN`, `t3cN`):

| TC param | TP `Person` field | Notes |
|---|---|---|
| `cN` | positional `[1]` | |
| `cNlink` | `link` | |
| `cNflag_o` / `cNflag` | `flag` | Same `flag_o`-wins-if-set rule as players. |
| `cNteam` | `team` | |
| (always) | `type = staff` | |
| `cNpos` | `role` | Per-coach role override (e.g. `cNpos=head coach`, `cNpos=analyst`). Pass-through; TP's `RoleUtil.readRoleArgs` normalizes. |
| `cNwins` + `cNwinsc` | `trophies` | Sum of both, same as players. |
| `cN` (no `cNpos` set) | `role = coach` | Default — coaches without an explicit `pos` are plain coaches. (No more `c1=head coach` heuristic.) |
| `scN` | `role = coach`, `status = sub` | |
| `fcN` | `role = coach`, `status = former` | |
| `cNsub` | `status = sub` | |

**Manual `tN*` tabs** (where `N` is `2` or `3`):

Read `tNtype` (with default fallback by index: `t2type` defaults to `sub`, `t3type` defaults to `former`):
- `tNtype = staff` → all `tNc*` people get `type=staff`, no special status. `tNp*` is unusual; tag those entries as `type=staff` too (with a warning/tracking category if desired) so they land in TP's Staff tab rather than collapsing into the Main tab.
- `tNtype = sub` → players & coaches get `status = sub`.
- `tNtype = former` → players & coaches get `status = former`.
- `tNtype = default` / unset for `t2`/`t3` → no status (active main roster — unusual but matches old TC's data and may deduplicate/collapse into the main roster).

`tNtitle` is dropped (TP has fixed/built-in tab labels).

If a page has both `s*` and `t2p*` populated (which old TC's `_parseArgs` would have folded together), the legacy wrapper preserves both groups in the TP `players` list. Duplicate entries — same `pageName` appearing in both groups — are deduplicated in the wrapper before passing to TP, with the entry from the more-explicit group (`t2p*`) winning. (Spec test covers this.)

**Status field interactions to verify** (per Rathoz's note on subs): the wrapper must produce a single, well-defined TP `status` per player when multiple TC signals are present. Combinations to test:
- `pNsub=true` + `pNdnp=true` → `status=sub`, `played=false` (sub status wins; `dnp` only affects `played`).
- `pNsub=true` + `pNleave=true` → `status=former` (`leave` upgrades from sub to former).
- `pNleave=true` + `pNdnp=true` → `status=former`, `played=false`.
- Source group `sN` + `pNsub=true` (redundant) → `status=sub` (no-op overlap).
- Source group `sN` + `subdnpdefault=true` (stashed arg from wiki template body) + no `pNplayed`/`pNresult` → `status=sub`, `played=false`, `results=false` via TP's defaulting (`results = played` when no explicit results input exists).
- Source group `fN` + `formerdnpdefault=true` (stashed arg from wiki template body) + no `pNplayed`/`pNresult` → `status=former`, `played=false`, `results=false` via the same defaulting.
- Source group `sN` + `subdnpdefault=true` + `pNresult=true` → `status=sub`, `played=true` (explicit `result` overrides the default).

`noVarDefault=true` (currently used by Counter-Strike) is an LPDB-compatibility flag. For non-main-roster entries that have no explicit `played` / `result` signal, set `played=false` and leave `results` unset so TP stores `results=false` and excludes those people from the LPDB player list. They can still render in the card.

Per-wiki variation is handled by the wiki's `Template:TeamCard` body (defaults flow through stashed args) or, in unusual cases, by the optional `preprocessCard` hook — see Section 7.

## Section 5 — LPDB storage and wiki variables

Storage is delegated to `TeamParticipants/Repository.save`; the legacy wrapper does **not** call `TeamCard/Storage.saveToLpdb`.

Compatible / intentionally preserved fields:

- Flat per-player / per-coach fields (`p1`, `p1flag`, `p1dn`, …, `c1`, …) via `Opponent.toLpdbStruct` / `Opponent.toLegacyParticipantData`, written into `opponentplayers` and mirrored into `players`.
- `qualifier`, `qualifierpage`, `qualifierurl` from `participant.qualification` (which the wrapper builds from the TC `qualifier` param per Section 3).
- `extradata.opponentaliases` from `participant.aliases` (built from TC `aliases`/`alsoknownas` per Section 3 — team2/team3 are not in here, they go to `contenders`).
- `individualprizemoney` calculated from prizepool merge — TP improves on TC by joining with existing prizepool placement records via `PageVariableNamespace('PrizePool')`, instead of writing independently.

Known LPDB shape deltas / rollout checks:

- **Object names:** `ranking_<team>` / `participant_tbd_<counter>` only apply in TP's no-prizepool-record fallback path. If a matching PrizePool record exists, TP reuses that record's existing `objectName` instead of generating a new one.
- **TBD counter namespace:** TP uses `PageVariableNamespace('TeamCards'):get('TBDs')`, not old TC's global `TBD_placements`. This is page-scoped and increments across TP blocks, but hybrid pages with old TC and new TP on the same page should be avoided during rollout.
- **Images:** old TC wrote placement-level `image = args.image1` and `imagedark = args.imagedark1` for non-TBD teams. TP does not currently write those columns. Treat this as accepted data loss only after auditing downstream consumers, or extend TP storage before rollout on affected wikis.
- **Players column shape:** TP mirrors `opponentplayers` into `players`; this can include broader fields (`pNteam`, `pNtemplate`, `pNfaction`, `pNid`) than old TC's `players` table. This is accepted unless a downstream query proves sensitive to missing/present subfields.
- **`noVarDefault`:** the wrapper must set `played=false` for default-unplayed filtered entries as described in Section 4 so `Repository.save` excludes them from LPDB player lists via `extradata.results`.

If a wiki has a wiki-side `Module:TeamCard/Custom` with `_saveToLpdb`, `_Players`, or `adjustLpdb` behavior, audit it before migration and translate the relevant behavior into TP / wrapper logic. Do not silently assume those hooks are irrelevant.

**Wiki vars:**

`TeamParticipantsRepository.setPageVars` already iterates each opponent's aliases and defines `<TeamName>_pN`, `<TeamName>_pNflag`, `<TeamName>_pNdn`, `<TeamName>_pNid`, `<TeamName>_pNfaction` (and `cN` analogs for staff). This covers what old TC's `_Players` did for per-team / per-player vars.

Old TC additionally set bare `team` / `teamRR` global page vars from the first card. A repo-wide grep (Lua + JS + SCSS) found no consumer, so the wrapper does **not** backfill them. If wiki-side modules turn out to depend on them during ArenaFPS rollout, we add the backfill — verified during this PR review.

**Storage gate:**

Old TC stored only when LPDB storage was enabled **and** the page was in mainspace. TP's controller checks `Logic.readBoolOrNil(args.store) ~= false and Lpdb.isStorageEnabled()`, and `Lpdb.isStorageEnabled()` does not itself enforce namespace. Therefore the wrapper must preserve the old mainspace gate by forcing `store=false` outside mainspace (or by using an equivalent render path that skips `Repository.save` outside mainspace). In mainspace, do not hardcode `store=true`; leave SaveLpdb / `disable_LPDB_storage` behavior intact.

## Section 6 — Tests, edge cases, deployment

**Tests** (in `lua/spec/`):

`teamcard_legacy_spec.lua` — fixture-based tests covering:
- Header/block stash mapping (`cols`, `padding`, `height`) and per-card template defaults (`defaultRowNumber`, `extraRows`, `subdnpdefault`, `formerdnpdefault`, `noVarDefault`, `t2type`, `t3type`) preserved from the wiki template body.
- Per-card mapping for the param matrix from the ArenaFPS example.
- `qualifier` parsing — raw text, `Invited`, internal wiki link to a tournament, internal link to a non-tournament page, external link, mixed text.
- `s*`-into-main fold-back: pages where `p1..pN` + `s1..sM` give a flat roster of N+M players with the trailing M marked `status=sub`.
- Coaches without `cNpos` default to `role=coach`; `cNpos=head coach` / `cNpos=analyst` pass through to TP `role`.
- `pNpos` and `cNpos` pass through unchanged; TP's `RoleUtil` does the normalization.
- `pNwins` + `pNwinsc` (and coach equivalents) sum into TP `trophies`.
- `pNjoindate`, `pNleavedate` pass through to TP `joindate`/`leavedate`.
- `pNflag_o` overrides `pNflag` and goes to TP `flag`.
- `pNid` maps to TP `id` / player `apiId`.
- `notes` and `inotes` both populate TP `notes` as `{[1]=value, highlighted=false}` (two entries when both set).
- `t2type=staff` with `t2c1..` and unusual `t2p1..` both becoming `type=staff` people so they render in the Staff tab.
- Multi-team rows (`team`+`team2`+`team3`) → TP `contenders` populated with **all three** team templates; opponent resolves to TBD with `potentialQualifiers`.
- Empty stash (no cards) — render nothing, no error.
- Malformed structure (header looks like a card, or no header at all) — wrapper emits a warning + adds a tracking category, continues rendering.
- Two `columns start`/`columns end` blocks on one page — second invocation only consumes its own stash.
- `{{TeamCardToggleButton|playerinfo=true}}` before a block → resulting TP render has `showplayerinfo=true`.
- `{{TeamCardToggleButton|p_extra=2}}` with `defaultRowNumber=5` from the card-template defaults → TP `minimumplayers=7`; two toggles with `p_extra=2` and `p_extra=3` → `minimumplayers=10`.
- `{{TeamCardToggleButton|note=Some text}}` → rendered output has the note text above the TP CardsGroup.
- Block with no toggle entry — wrapper handles the absence cleanly (no `showplayerinfo`, no note div).
- Storage gate: when SaveLpdb / LPDB storage is disabled, no LPDB writes happen; outside mainspace the wrapper forces storage off even if TP storage would otherwise be enabled.
- `subdnpdefault=true` (stashed arg) + source group `s*` + no `played`/`result` set → `played=false`, `results=false` on the resulting TP person.
- `formerdnpdefault=true` (stashed arg) + source group `f*` + no `played`/`result` set → `played=false`, `results=false`, `status=former`.
- `noVarDefault=true` (CS-style) excludes default-unplayed non-main roster entries from the LPDB player list.
- RocketLeague-style `preprocessCard` test — `sub1..3` rewritten to `p1..3` with `status=sub`, `sub4..12` to `s4..12`, `ex1..7` to `f1..7`.
- Status precedence cases listed in Section 4 ("Status field interactions to verify").
- LPDB fallback objectName generation for non-prizepool teams and TBD counter increment using `TeamCards.TBDs`; prizepool-matched teams reuse prizepool object names.
- Accepted LPDB image delta is covered by a fixture/snapshot or explicit assertion that `image` / `imagedark` are not written unless TP storage is extended.

ArenaFPS does not have a Custom file under the new design; `Template:TeamCard columns end` invokes commons `Module:TeamCard/Legacy` directly. No ArenaFPS-specific spec needed. (A Custom-file spec lives with the first wiki that adds one — likely RocketLeague when it migrates.)

**Edge cases summarized:**

- Empty stash — render nothing.
- Malformed structure (header missing or looks like a card) — wrapper emits warning + tracking category; renders best-effort. (Per Rathoz: "the `columns end` template might be missing too" — making affected pages findable matters more than silent recovery.)
- `team='TBD'` cards — produce TBD opponent without errors.
- Per-card `disable_storage=true` — ignored. (Bot pre-pass can lift such cards out of the columns block if needed.)
- Two separate column blocks on one page — `Template.retrieveReturnValues` deletes-and-returns, so each block consumes only its own stash.
- Multi-team rows — TP `contenders` list is populated from `team`+`team2`+`team3` (all three). Opponent resolves to TBD, `potentialQualifiers` carries the candidate teams, TP's `Repository.save` stores `extradata.potentialQualifiers` and writes `participant_tbd_<counter>` records.
- Manual `t2p…`/`t3p…` tabs — bucketed by `tNtype`; `tNtitle` dropped.
- `mergeStaffTabIfOnlyOneStaff` — TP's existing config handles single-staff merge automatically; the wrapper just passes staff through.

**Deployment** (out of scope for the implementation PR, listed for rollout planning):

1. Land the commons Lua module (`Module:TeamCard/Legacy`) in this repo. ArenaFPS does not need a per-wiki Custom file under the new design.
2. **Pre-rollout audit:** add a tracking category to old `Module:TeamCard` for pages where `args.lpdb_prefix` is set, to surface affected pages before per-wiki migration. Also audit whether the wiki has a wiki-side `Module:TeamCard/Custom` and whether downstream consumers rely on placement `image` / `imagedark`.
3. Bot-edit ArenaFPS pages without `{{TeamCard columns start}}` / `{{TeamCard columns end}}` to add the wrappers — including the `{{box|start}}` / `{{box|break}}` / `{{box|end}}` rewrite (regex sketch in Out of scope).
4. On-wiki (locally on the target wiki, shadowing commons initially): edit `Template:TeamCard columns start`, `Template:TeamCard`, `Template:TeamCard columns end`, and the **per-wiki** `Template:TeamCardToggleButton` wrapper per the table in Section 1. Preserve wiki-baked TeamCard defaults and `FRAME_SET_VOLATILE`.
5. Migration order within a wiki: migrate `Template:TeamCard` / columns start/end before the toggle wrapper. The old toggle's `tournament_teamplayers_extra` vardefine is needed by non-migrated TC cards; replacing the toggle first can break `p_extra` for old TC renders.
6. Verify a sample of ArenaFPS pages render correctly (controls, tabs, placements, LPDB writes, toggle button → TP controls strip).
7. Roll out wiki-by-wiki, adding per-wiki Custom files as each comes online.
8. After several wikis are validated, switch the templates on **commons** to the new bodies and remove the local copies one wiki at a time.

## Section 7 — Per-wiki customization

There is **no Lua-level per-wiki config table.** Wiki-specific behavior already lives in two places that the wrapper reads from:

1. **The wiki's `Template:TeamCard` body** — wikis bake their settings here as named args on the invoke (`|defaultRowNumber=5|subdnpdefault=true|maxPlayers=20|...`). The rollout-time edit must preserve those named args while changing the invoked module/function to `Template.stashArgs`; then they land in the stashed entry for each card. The wrapper recognizes the biz-logic-relevant ones (Section 2) and ignores the rest.

2. **MediaWiki page vars / template arg fallback chains** — patterns like `{{#var:tournament_teamplayers|{{{players|5}}}}}` are resolved at template-expansion time and land as plain values in the stash. No wrapper-side handling needed.

**Optional `Module:TeamCard/Legacy/Custom`** — only created for wikis that need Lua-level preprocessing of stashed args (e.g. RocketLeague's `sub1..12` / `ex1..7` aliasing). Implements `preprocessCard(args) -> args`. See Section 1 for the file shape.

**Wiki rollout decision tree:**

| Wiki situation | Per-wiki Custom file | Per-wiki Lua change |
|---|---|---|
| Standard TC args, defaults baked in template body (ArenaFPS, CS, dota2, LoL, HoK, R6, OW, Valorant, …) | None | None — `Template:TeamCard columns end` invokes commons `Module:TeamCard/Legacy` directly. |
| Heavy wikitext-level arg aliasing (RocketLeague) | `Module:TeamCard/Legacy/Custom.lua` with `preprocessCard` | Move the aliasing logic from wikitext into Lua (cleaner). |
| Future wiki with needs the above two don't cover | Add a new hook (`preprocessHeader`, `preprocessToggle`, etc.) | Add the hook to commons and use it on that wiki. |

**Why no config table:** earlier drafts had a per-wiki config dict (`coachRoles`, `positionMapping`, `playerParamMap`, etc.). Examining 9 wikis' actual `Template:TeamCard` bodies showed that everything currently expressible as a config knob is already encoded in the wiki template body — duplicating it into Lua tables would just create two sources of truth. The single remaining genuinely-Lua-level concern is arg preprocessing (RL), which is better expressed as a function than a config dict.

## Section 8 — Groupings (multiple TC blocks per page)

A real tournament page often has several `{{TeamCard columns start}}`/`{{TeamCard columns end}}` blocks — e.g. one per group stage section (`== Group A ==`, `== Group B ==`), or per day. After the wrapper, each TC block becomes one `TeamParticipants` render. We need to coordinate their state so the page reads correctly.

**What works for free** (no wrapper effort):

- `Template.retrieveReturnValues('LegacyTeamCard')` deletes-and-returns: each `columns end` consumes only its own stash.
- TBD counter (`teamCardsVars:get('TBDs')` in `Repository.save`) is page-scoped and increments across blocks — `participant_tbd_1`, `_2`, … get unique objectNames.
- `teamParticipantRostersSwitchGroupId` (in `Roster.lua`) increments across blocks — each roster gets its own switch-group id.
- TP's `setPageVars` runs once per opponent regardless of which block; `<TeamName>_pN…` page vars don't collide because team names disambiguate them.

**What needs wrapper coordination:**

- **Controls (`Show rosters` / `Compact view` / `Enable hover` switches)**. `Controller.fromTemplate` reads `externalControlsRendered` to decide whether to render them, but **nothing in the controller path sets this var**. Naïvely translating multiple TC blocks → multiple TP renders means every block shows its own controls strip. On a 4-group-stage page that's 4 control bars, which is wrong.

  **Resolution:** after every successful TP render, the legacy wrapper sets `teamParticipantsVars:set('externalControlsRendered', 'true')`. No separate "first invocation" var is needed: the first controller call sees the var unset and renders controls; the wrapper then sets it; later controller calls see it set and suppress controls.

  Net effect for a multi-group page: one shared controls strip at the top of the first group's block, plain card grids for the rest. Same behavior the existing TP `externalUsage` path already supports — the wrapper just opts into it implicitly.

**What stays out of scope:**

- Cross-block deduplication of teams. If the same team appears in two blocks (rare — usually the same team isn't in multiple groups), TP writes two LPDB records. That matches old TC behavior.
- Custom per-block headers / titles. The legacy wrapper doesn't render any wikitext between blocks; section headers come from the surrounding page wikitext, untouched.

**Tests** to add to the spec list in Section 6:
- Two-block page: first block renders controls; second block has no controls strip.
- TBD counter increments across blocks: block 1 with one TBD card → `participant_tbd_1`, block 2 with one TBD card → `participant_tbd_2`.
- `team` / `teamRR` page vars are not backfilled by the wrapper.

## Open questions

None at design stage.

## Decisions log

| Decision | Choice | Reason |
|---|---|---|
| Naked `{{TeamCard}}` runs without columns markers | Bot-edit pages first; wrapper assumes markers always present | Cleaner wrapper; matches existing PrizePool legacy rollout playbook. |
| Module structure | `Module:TeamCard/Legacy` (commons), with per-wiki `Module:TeamCard/Legacy/Custom` only when a wiki needs Lua-level preprocessing | Most wikis need no per-wiki Lua file; their `Template:TeamCard` body carries the wiki-specific defaults. RocketLeague is the one known wiki needing a Custom file (for arg aliasing). |
| Wiki-template entry points | `columns start`/`TeamCard` stash; `columns end` runs | Mirrors PrizePool/Legacy stash pattern. |
| LPDB storage | Delegate to TP (`Repository.save`); do not call `TeamCard/Storage.saveToLpdb` | TP produces the important legacy participant/qualifier/alias fields and merges with prizepool records, but known deltas (`image`/`imagedark`, objectName reuse, broader `players` shape) are documented and audited. |
| Multi-team rows (`team2`/`team3`) | TP `contenders` (TBD with `potentialQualifiers`) | Maps to the existing TP semantics for "any of these teams"; matches old TC LPDB behavior (`team='TBD'`) more accurately than aliases would. |
| Team display vs. template | TC `link` (or fallback `team`) → TP `[1]` (template); TC `team` (display name) dropped | TP derives display from team template; old TC's `team` was just a display override and has no TP equivalent. |
| Coach role mapping | Default `role=coach`; `cNpos` overrides per coach | Per Rathoz: don't assume `c1`=head coach. `cNpos` is the canonical signal; coaches without it are plain coaches. |
| `pNpos` / `cNpos` | Pass through to TP `role` (no `positionMapping` config layer) | TP's `RoleUtil` normalizes. Forced numeric mapping (e.g. dota2 `1` → `carry`) deferred until that wiki migrates. |
| `pNwins` / `pNjoindate` / `pNleavedate` | Pass through to TP `trophies` / `joindate` / `leavedate` | Joindate/leavedate assume the in-flight TP PR has landed. |
| Helper module | None | TP/Repository covers the storage and per-team-vars work; no separate helper is needed for this wrapper. |
| Wiki variables | TP's `setPageVars` covers per-team / per-player / per-staff vars; wrapper does **not** backfill global `team` / `teamRR` | Repo-wide Lua/JS/SCSS grep found no consumer. If wiki-side wikitext consumers appear during rollout, add a targeted backfill later. |
| Per-card `disable_storage` / `lpdb_prefix` | Out of scope | TP's `store` is top-level (header-level disable maps to it); TP doesn't have `lpdb_prefix`. Edge cases revisited per-wiki when needed. |
| Wiki customization style | **No Lua config table.** Wiki `Template:TeamCard` body is the source of truth for per-wiki defaults (already where they live today). Optional `preprocessCard` hook on `Module:TeamCard/Legacy/Custom` for wikis with arg aliasing (RL). | Examined 9 wikis' actual templates: defaults already encoded in template bodies. A Lua config dict would just duplicate them. The single concern needing real Lua-level handling is RL-style arg aliasing, which is best expressed as a function. |
| Per-wiki Custom file | OPTIONAL — not required for most wikis | ArenaFPS, CS, dota2, LoL, HoK, R6, OW, Valorant: no Custom file. RL: Custom with `preprocessCard`. |
| Multiple TC blocks per page (groupings) | Wrapper sets `externalControlsRendered` after first block; subsequent blocks reuse the controls strip from the first | Avoids 4× control bars on group-stage pages. Uses TP's existing externalControls coordination, just opts in implicitly. |
| Subst-based wrapper | Not used initially; revisit later | Per Rathoz: too unstable to start with. Land the live wrapper, fix mapping bugs, then look at subst. |
| StarCraft / SC2 / Stormgate coverage | Not covered by this wrapper | Per hjpalpha: those wikis use TeamCard variants that aren't compatible with this approach. |
| `team` / `teamRR` global page vars | Not backfilled | Repo-wide grep found no consumer (Lua + JS + SCSS). If wiki-side modules turn out to depend on them, add backfill during rollout. |
| `store` / top-level `date` hardcoded | Do not set top-level `date`; only force `store=false` outside mainspace | In mainspace, hardcoding `store` would override SaveLpdb wiki vars. Outside mainspace, forcing storage off preserves old TC's `Namespace.isMain()` gate. |
| `disable_storage` / `nostorage` (header) | Dropped from header table | Per Rathoz: TC doesn't actually set these on the header. Only per-card occurrences exist, and per-card storage opt-out is out-of-scope. |
| Malformed-structure handling | Emit warning + tracking category, don't silently fall back | Per Rathoz: a missing `columns end` is a structural issue worth surfacing. |
| `team` in contenders | Include `team` along with `team2`/`team3` | Per Rathoz: all three teams are candidates, not just team2/3. |
| Notes value placement | Positional `[1]`, not `text=` | Per Rathoz: TP's note table uses `[1]` for the value. |
| MW `<br>` workaround | Wrap stash invocations in empty `<div></div>` | Per Rathoz/hjpalpha: without it, MW parser inserts `<br>` per `#invoke`. |
| Commons template rollout | Local override per wiki initially, then commons rollout when validated | Per hjpalpha/Rathoz: `Template:TeamCard columns start/end` live on commons; per-wiki rollout requires shadowing locally first. |
| `Template:TeamCardToggleButton` handling | Edit each per-wiki wrapper to stash raw toggle args with `__source=toggle`; wrapper folds args into TP top-level (`showplayerinfo`, `minimumplayers` += summed `p_extra`, notes rendered above CardsGroup) | Editing commons `/Base` alone is insufficient because per-wiki wrappers forward only subsets of args. |
| Stash entry kinds | `__source` sentinel (`toggle` / `header` / `card`) on each `stashArgs` invocation | Robust partitioning of mixed entries; avoids brittle heuristics on field presence. |
| Bot regex pre-pass | Documented in Out-of-scope | Per hjpalpha: regex sketch for rewriting `{{Box | start/break/end}}` patterns into `columns start/end`. |
| Tracking category for `lpdb_prefix` | Add to old TC | Per hjpalpha: surface affected pages before per-wiki rollout. |
| `subdnpdefault` / `formerdnpdefault` | Recognized as per-card stashed args (from wiki template body), not Lua config flags | These already live in wiki template bodies (Valorant, RL); reading from stash avoids duplication. |
| Param-rename config keys (`playerParamMap` etc.) | Not introduced — handled via optional `preprocessCard` hook if needed | Param renaming is genuinely Lua-level work; better expressed as a function than a config table. RL is the only known case so far. |
