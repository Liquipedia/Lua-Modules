# TeamCard → TeamParticipants Legacy Wrapper

**Date:** 2026-05-06
**Status:** Design (awaiting user review)
**Ticket:** https://gitlab.com/teamliquid-dev/liquipedia/issue-bucket/-/work_items/1100

## Goal

Replace the old `Module:TeamCard` rendering with `Module:TeamParticipants/Controller` on existing tournament pages, without touching the page wikitext. The conversion is done by a Legacy wrapper module that intercepts the `{{TeamCard columns start}}` / `{{TeamCard}}` / `{{TeamCard columns end}}` template invocations, reshapes their args into TeamParticipants input, and renders.

Rollout is wiki-by-wiki, starting with ArenaFPS. LPDB storage is delegated to TeamParticipants — its `Repository.save` already produces a record shape backwards-compatible with TeamCard's writes (same `objectName` scheme, legacy participant fields via `Opponent.toLegacyParticipantData`, qualifier fields, individualprizemoney, opponentaliases).

## Out of scope

- Per-wiki bot-edit work to insert `{{TeamCard columns start}}` / `{{TeamCard columns end}}` around naked `{{TeamCard}}` runs. The wrapper assumes columns markers are always present.
- The on-wiki template edits themselves (`Template:TeamCard*`). Those happen at deploy time.
- Per-card `disable_storage` / `nostorage` — TP's `store` flag is top-level. The wrapper only honors these on the header (`columns start`). Per-card opt-out would require a TP extension; revisit when a wiki actually needs it.
- Per-card `lpdb_prefix` — old TC supported this to disambiguate same-team records on a single page (`ranking_<prefix>_<team>`). TP doesn't. ArenaFPS doesn't appear to use it; flag this as a known gap and revisit when a wiki that does use it comes up for migration.
- Adding `joindate`/`leavedate` to TP's player input parser and `setPageVars`. There's an in-flight TP PR doing this, which we assume lands before this wrapper ships; the wrapper just passes the values through.

## Architecture

```
Wiki templates (on-wiki, edited at deploy):
  Template:TeamCard columns start  → invoke Module:Template fn=stashArgs namespace=LegacyTeamCard
  Template:TeamCard                → invoke Module:Template fn=stashArgs namespace=LegacyTeamCard
  Template:TeamCard columns end    → invoke Module:TeamCard/Legacy/Custom fn=run

In-repo Lua modules (new):
  Module:TeamCard/Legacy            (lua/wikis/commons/TeamCard/Legacy.lua)
  Module:TeamCard/Legacy/Custom     (lua/wikis/<wiki>/TeamCard/Legacy/Custom.lua, per wiki)

In-repo Lua modules (existing, reused):
  Module:TeamParticipants/Controller — render and store via TP.fromTemplate-equivalent path
  Module:TeamParticipants/Repository — TP's existing storage; backwards-compatible with TC LPDB writes
  Module:Template                   — stashArgs/retrieveReturnValues
```

The flow on `{{TeamCard columns end}}` invocation:

1. `Custom.run` calls `LegacyTeamCard.run(Custom.config)` (where `Custom.config` is a table of per-wiki overrides — see Section 7).
2. `Legacy.run` retrieves all stashed args via `Template.retrieveReturnValues('LegacyTeamCard')`.
3. First entry = header (from `columns start`); remaining entries = cards (from each `TeamCard`).
4. Header is mapped into TP top-level args (`minimumplayers`, `store`, `date`); per-card `import=false` is set on each opponent.
5. Each card is mapped into a TP `Opponent` arg shape (Sections 3 + 4 below), applying `config` for wiki-specific renames / role mappings.
6. The wrapper sets the `team` / `teamRR` global page vars from the first non-TBD card (preserving an old TC behavior that TP's `setPageVars` doesn't cover).
7. The collected TP args are passed into a render path equivalent to `TeamParticipantsController.fromTemplate`, which itself calls `TeamParticipantsRepository.save` (storing in a TC-compatible shape) and `TeamParticipantsRepository.setPageVars` (defining the per-team / per-player wiki vars).

## Section 1 — Module layout & wiki templates

**`Module:TeamCard/Legacy`** (commons): the mapping pipeline as small functions.
Exports:
- `LegacyTeamCard.run(config)` — entry point, takes the wiki Custom's config table.
- `LegacyTeamCard.mapHeader(header) -> tpHeaderArgs`
- `LegacyTeamCard.mapCard(tcArgs, config) -> tpOpponentArgs`
- `LegacyTeamCard.mapPlayers(tcArgs, config) -> personArgs[]`
- `LegacyTeamCard.mapCoaches(tcArgs, config) -> personArgs[]`
- `LegacyTeamCard.parseQualifier(rawQualifier) -> qualificationStruct`

Wikis customize via the `config` table (Section 7), not callback hooks.

**`Module:TeamCard/Legacy/Custom`** (per wiki, e.g. `lua/wikis/arenafps/TeamCard/Legacy/Custom.lua`): thin wiki wrapper exposing a config table. For ArenaFPS (and any wiki with no special needs), the file is:

```lua
local Lua = require('Module:Lua')
local LegacyTeamCard = Lua.import('Module:TeamCard/Legacy')

local Custom = {}

Custom.config = {} -- empty: use commons defaults

function Custom.run()
    return LegacyTeamCard.run(Custom.config)
end

return Custom
```

Wikis with TC param differences set fields in `Custom.config` to override the defaults. The full config schema and defaults are described in Section 7. (Earlier hook-style overrides like `customHeader`/`customCard`/`customPlayer`/`customCoach` are gone — config-only.)

**Wiki-side template edits** (out-of-repo, but documented for the rollout):

| Template | Old body | New body |
|---|---|---|
| `Template:TeamCard columns start` | `<div class="template-box">…<#vardefine>` | `{{#invoke:Lua\|invoke\|module=Template\|fn=stashArgs\|namespace=LegacyTeamCard}}` |
| `Template:TeamCard` | `{{#invoke:Lua\|invoke\|module=TeamCard\|fn=draw\|...}}` | `{{#invoke:Lua\|invoke\|module=Template\|fn=stashArgs\|namespace=LegacyTeamCard}}` |
| `Template:TeamCard columns end` | `</div>` | `{{#invoke:Lua\|invoke\|module=TeamCard/Legacy/Custom\|fn=run}}` |

## Section 2 — Header mapping

The first retrieved stash entry comes from `{{TeamCard columns start}}`. Map:

| TC header param | TP top-level arg | Notes |
|---|---|---|
| `defaultRowNumber` | `minimumplayers` | Closest semantic match. |
| `disable_storage`/`nostorage` (header-level) | `store = false` (top-level) | Honored only when set on the header, since TP's `store` is top-level. Per-card occurrences are ignored (out-of-scope). |
| `cols`, `defaultHeight`, `c2OnNewLine`, `t2title`, `t3title`, `favorDefaultRowNumber`, `maxPlayers`, `sidetabs`, `nobgcolor`, `noTeamLinks`, `noQualifierLogos`, `qualifierLogosType` | dropped | Display-only features absent from TP. |

Hardcoded by the wrapper:
- `import = false` is set **per card** (not at header level — TP reads `import` off each Opponent), so old pages use explicit rosters.
- `store` defaults to true (TP's default) unless the header disabled storage. TP's `Repository.save` produces records with the same `objectName` shape as old TC and the same legacy participant fields via `Opponent.toLegacyParticipantData`.
- `date` — passed through if set on header, else TP's tournament-date default applies.

Before invoking the TP render, the wrapper also sets two global page vars from the first non-TBD card (matching old TC behavior): `team` (resolved team name at `tournament_date`) and `teamRR` (redirect-resolved name). TP's `setPageVars` does the per-team `<TeamName>_pN` style vars itself, so those are not duplicated here.

If the first stash entry contains a `team` key (i.e. it looks like a card, not a header — defensive case for pages where `columns start` is missing or malformed), treat all entries as cards and synthesize an empty header.

## Section 3 — Per-card → Opponent mapping

For each card stash entry, build one TP `Opponent` arg.

**Team identity:**

| TC | TP | Notes |
|---|---|---|
| `link` (or fallback to `team`) | positional `[1]` (template) | TC's `team` is the display name, `link` is the team template. The wrapper uses `args.link or args.team` for the TP template arg. |
| `team` (display name) | dropped | TP derives display from the team template; no separate display override. |
| `team2`/`team3` set | TP `contenders` (list of team templates) | Maps to TP's `contenders` parsing path: opponent becomes TBD with `potentialQualifiers` populated from each team template (`Opponent.readOpponentArgs({type=team, template=…})`). `link2`/`link3` are used as templates if present. |
| `image1`/`imagedark1`/`imagesize` | dropped | TP gets logos from team templates. Image override (#7295) was reverted (#7449). |
| `flag` (header flag) | dropped | No TP equivalent. |

**Card-level metadata:**

| TC | TP | Notes |
|---|---|---|
| `qualifier` | `qualification.{method,page,url,text,placement}` | See parser rules below. |
| `notes` | appended to `notes` list as `{text=notes, highlighted=false}` | |
| `inotes` | appended to `notes` list as `{text=inotes, highlighted=false}` | If both `notes` and `inotes` are set, both entries are added to the TP `notes` list. |
| `date` | `date` | |
| `aliases` / `alsoknownas` | `aliases` (semicolon-joined) | Just `aliases`/`alsoknownas` — team2/team3 entries are not folded in here; they go to `contenders` (see Team identity above). |
| `disable_storage`/`nostorage` (per-card) | dropped | Per-card storage opt-out is out-of-scope (header-level only — see Section 5). |
| `placement`, `context`, `preview`, `ref`, `class`, `showroster`, `hideroster` | dropped | Pure formatting / display. |
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
| `pNfaction` / `pNrace` | `faction` | |
| `pNdnp` (truthy) | `played = false` | `dnp` wins over `played`/`result` if both set. |
| `pNplayed` / `pNresult` | `played` (boolean) | |
| `pNleave` (truthy) | `status = former` | |
| `pNsub` (truthy) | `status = sub` | |
| Source group `sN` | `status = sub` | Same as `pNsub`. |
| Source group `fN` | `status = former` | |
| `pNpos` | `role` | Passed through; TP's `RoleUtil.readRoleArgs` normalizes it. Wiki-specific value mapping (e.g. `pNpos=1` → `role=carry`) goes through the per-wiki config (Section 7). |
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
| `cNwins` + `cNwinsc` | `trophies` | Sum of both, same as players. |
| `c1` (default) | `role = head coach` | First coach is head coach. Override via per-wiki `coachRoles` config (Section 7). |
| `c2..cN` (default) | `role = coach` | Override via per-wiki `coachRoles` config. |
| `scN` | `role = coach`, `status = sub` | |
| `fcN` | `role = coach`, `status = former` | |
| `cNsub` | `status = sub` | |

**Manual `tN*` tabs** (where `N` is `2` or `3`):

Read `tNtype` (with default fallback by index: `t2type` defaults to `sub`, `t3type` defaults to `former`):
- `tNtype = staff` → all `tNc*` people get `type=staff`, no special status. `tNp*` is unusual here but treated as `type=player`.
- `tNtype = sub` → players & coaches get `status = sub`.
- `tNtype = former` → players & coaches get `status = former`.
- `tNtype = default` / unset for `t2`/`t3` → no status (active main roster — unusual but matches old TC's data).

`tNtitle` is dropped (TP has fixed/built-in tab labels).

If a page has both `s*` and `t2p*` populated (which old TC's `_parseArgs` would have folded together), the legacy wrapper preserves both groups in the TP `players` list. Duplicate entries — same `pageName` appearing in both groups — are deduplicated in the wrapper before passing to TP, with the entry from the more-explicit group (`t2p*`) winning. (Spec test covers this.)

Per-wiki tweaks to player/coach mapping go through the config table (see Section 7), not callback hooks.

## Section 5 — LPDB storage and wiki variables

Storage is delegated to `TeamParticipants/Repository.save`, which already produces a record shape backwards-compatible with TeamCard's writes:

- `objectName`: `ranking_<team>` for resolved teams, `participant_<team>_<counter>` for TBDs (matches `TeamCard/Storage._getLpdbObjectName`'s scheme).
- Flat per-player / per-coach fields (`p1`, `p1flag`, `p1dn`, …, `c1`, …) via `Opponent.toLegacyParticipantData`, written into the `players` / `opponentplayers` columns.
- `qualifier`, `qualifierpage`, `qualifierurl` from `participant.qualification` (which the wrapper builds from the TC `qualifier` param per Section 3).
- `extradata.opponentaliases` from `participant.aliases` (built from TC `aliases`/`alsoknownas` per Section 3 — team2/team3 are not in here, they go to `contenders`).
- `individualprizemoney` calculated from prizepool merge — TP improves on TC by joining with existing prizepool placement records via `PageVariableNamespace('PrizePool')`, instead of writing independently.

So the legacy wrapper does **not** call `TeamCard/Storage.saveToLpdb` and does **not** lift any helpers out of the wiki-side `Module:TeamCard`. It maps args correctly and lets TP render+store.

**Wiki vars:**

`TeamParticipantsRepository.setPageVars` already iterates each opponent's aliases and defines `<TeamName>_pN`, `<TeamName>_pNflag`, `<TeamName>_pNdn`, `<TeamName>_pNid`, `<TeamName>_pNfaction` (and `cN` analogs for staff). This covers what old TC's `_Players` did for player vars.

The wrapper additionally backfills two globals before calling the TP render, since TP doesn't define these and they're read by other modules:

- `team` — resolved team name at `tournament_date` (computed as `Team.page(nil, name, tournament_date)` for the first non-TBD card's `team`/`link`).
- `teamRR` — `mw.ext.TeamLiquidIntegration.resolve_redirect(team)`.

Both are set via `Variables.varDefine`. If all cards are TBD, neither is set (matching old TC's behavior of leaving them unset for TBD-only pages).

**Storage gate:**

Storage runs whenever:
- `Lpdb.isStorageEnabled()` (TP's existing check), AND
- The header didn't set `disable_storage` / `nostorage`.

Per-card `disable_storage` is ignored (per "Out of scope"). If a wiki has pages where this matters, the bot pre-pass can lift such cards out of the columns block.

## Section 6 — Tests, edge cases, deployment

**Tests** (in `lua/spec/`):

`teamcard_legacy_spec.lua` — fixture-based tests covering:
- Header mapping with all known params.
- Per-card mapping for the param matrix from the ArenaFPS example.
- `qualifier` parsing — raw text, `Invited`, internal wiki link to a tournament, internal link to a non-tournament page, external link, mixed text.
- `s*`-into-main fold-back: pages where `p1..pN` + `s1..sM` give a flat roster of N+M players with the trailing M marked `status=sub`.
- `c1`-as-head-coach with `c2..cN` as coach (default `config.coachRoles`).
- `config.coachRoles = {'head coach', 'assistant coach'}` override produces the expected per-index labels.
- `config.positionMapping` translates TC `pNpos` values to TP `role` values for a wiki that uses non-standard labels.
- `pNwins`, `pNjoindate`, `pNleavedate` pass through to TP `trophies`/`joindate`/`leavedate`.
- `pNflag_o` overrides `pNflag` and goes to TP `flag`.
- `notes` and `inotes` both populate TP `notes` (two entries when both set).
- `t2type=staff` with `t2c1..` becoming `type=staff` people.
- Multi-team rows (`team`+`team2`+`team3`) → TP `contenders` populated with each team template; opponent resolves to TBD with `potentialQualifiers`.
- Empty stash (no cards) — render nothing, no error.
- Header missing (first stash entry has `team`) — defensive fallback path.
- Two `columns start`/`columns end` blocks on one page — second invocation only consumes its own stash.
- Header `disable_storage=true` → top-level `store=false` on TP.
- Per-card `disable_storage=true` is ignored (documented behavior).
- `team` / `teamRR` global vars are defined from the first non-TBD card.

ArenaFPS Custom file is empty (just delegates to commons), so no separate spec.

**Edge cases summarized:**

- Empty stash — render nothing.
- Missing header — synthesize empty header from first card-shaped entry.
- `team='TBD'` cards — produce TBD opponent without errors.
- Header `disable_storage=true` — top-level `store=false`, no LPDB writes for any card; wiki vars and TP render still happen.
- Per-card `disable_storage=true` — ignored. (Bot pre-pass can lift such cards out of the columns block if needed.)
- Two separate column blocks on one page — `Template.retrieveReturnValues` deletes-and-returns, so each block consumes only its own stash.
- Multi-team rows — TP `contenders` list is populated from `team`/`team2`/`team3`. Opponent resolves to TBD, `potentialQualifiers` carries the candidate teams, TP's `Repository.save` stores `extradata.potentialQualifiers` and writes `participant_tbd_<counter>` records.
- Manual `t2p…`/`t3p…` tabs — bucketed by `tNtype`; `tNtitle` dropped.
- `mergeStaffTabIfOnlyOneStaff` — TP's existing config handles single-staff merge automatically; the wrapper just passes staff through.

**Deployment** (out of scope for the implementation PR, listed for rollout planning):

1. Land the Lua modules in this repo (commons + ArenaFPS Custom).
2. Bot-edit ArenaFPS pages without `columns start`/`columns end` to add the wrappers.
3. On-wiki: edit `Template:TeamCard columns start`, `Template:TeamCard`, `Template:TeamCard columns end` per the table in Section 1.
4. Verify a sample of ArenaFPS pages render correctly (controls, tabs, placements, LPDB writes).
5. Roll out wiki-by-wiki, adding per-wiki Custom files (and bot pre-passes) as each comes online.

## Section 7 — Per-wiki config schema

`Module:TeamCard/Legacy.run(config)` accepts a table of config overrides. Defaults live in commons and cover everything needed for ArenaFPS. Wikis with TC quirks override individual keys in their `Custom.config`.

Initial schema (start small; extend only when a concrete wiki needs it):

| Key | Type | Default | Purpose |
|---|---|---|---|
| `coachRoles` | `string[]` | `{'head coach', 'coach'}` | Role assigned to `cN` by index — `coachRoles[1]` → `c1`, `coachRoles[2]` → `c2`, with `'coach'` for any further coaches beyond the array length. |
| `positionMapping` | `table<string, string>` | `{}` (identity / TP-RoleUtil-only) | Maps TC `pNpos` values to TP `role` values when the wiki uses non-standard position labels (e.g. dota2 might map `1` → `'carry'`). When empty, `pNpos` is passed through as-is and `RoleUtil.readRoleArgs` normalizes it. |
| `playerParamMap` | `table<string, string>` | `{}` | Optional per-wiki rename of TC player suffixes to TP person fields (e.g. `{ ['pNheroes'] = 'extradata.heroes' }`) for wiki-specific input. Empty default; rarely needed. |
| `coachParamMap` | `table<string, string>` | `{}` | Same shape as `playerParamMap`, applied to `cN`/`scN`/`fcN` etc. |
| `cardParamMap` | `table<string, string>` | `{}` | Per-wiki rename of TC card-level params to TP opponent fields. |

**ArenaFPS Custom.config** (concrete starting state): `{}` — all defaults.

**Why config over hooks:** Suggestion from Rikard. The previous hook-style design (`customHeader`, `customCard`, etc.) gave per-wiki Custom modules unbounded power to mutate the mapping pipeline, which is overkill for a legacy wrapper meant to be eventually deleted. A small config surface is enough for the differences that actually exist between wikis (mostly: which positional labels matter, what role labels coaches get) and keeps each wiki's Custom file declarative.

If a future wiki needs something the config can't express, we add a new config key — preferred over reintroducing hooks.

## Section 8 — Groupings (multiple TC blocks per page)

A real tournament page often has several `{{TeamCard columns start}}`/`{{TeamCard columns end}}` blocks — e.g. one per group stage section (`== Group A ==`, `== Group B ==`), or per day. After the wrapper, each TC block becomes one `TeamParticipants` render. We need to coordinate their state so the page reads correctly.

**What works for free** (no wrapper effort):

- `Template.retrieveReturnValues('LegacyTeamCard')` deletes-and-returns: each `columns end` consumes only its own stash.
- TBD counter (`teamCardsVars:get('TBDs')` in `Repository.save`) is page-scoped and increments across blocks — `participant_tbd_1`, `_2`, … get unique objectNames.
- `teamParticipantRostersSwitchGroupId` (in `Roster.lua`) increments across blocks — each roster gets its own switch-group id.
- TP's `setPageVars` runs once per opponent regardless of which block; `<TeamName>_pN…` page vars don't collide because team names disambiguate them.

**What needs wrapper coordination:**

- **Controls (`Show rosters` / `Compact view` / `Enable hover` switches)**. `Controller.fromTemplate` reads `externalControlsRendered` to decide whether to render them, but **nothing in the controller path sets this var**. Naïvely translating multiple TC blocks → multiple TP renders means every block shows its own controls strip. On a 4-group-stage page that's 4 control bars, which is wrong.

  **Resolution:** the legacy wrapper sets `teamParticipantsVars:set('externalControlsRendered', 'true')` after its first invocation on a page. The first TC block renders controls; subsequent blocks see the var and skip them. The wrapper detects "first invocation" by checking another page var (e.g. `LegacyTeamCardFirstBlockRendered`); on first call, it does nothing extra (lets TP render controls), then sets both vars. On subsequent calls, controls are suppressed.

  Net effect for a multi-group page: one shared controls strip at the top of the first group's block, plain card grids for the rest. Same behavior the existing TP `externalUsage` path already supports — the wrapper just opts into it implicitly.

- **`team` / `teamRR` global vars** (Section 5 backfill). These are set from the *first non-TBD card* of the *first block*. The wrapper guards with `Variables.varDefault('team')` — if already set on this page (by an earlier block or another module), it doesn't overwrite. Old TC's behavior was the same (first card on page wins).

**What stays out of scope:**

- Cross-block deduplication of teams. If the same team appears in two blocks (rare — usually the same team isn't in multiple groups), TP writes two LPDB records. That matches old TC behavior.
- Custom per-block headers / titles. The legacy wrapper doesn't render any wikitext between blocks; section headers come from the surrounding page wikitext, untouched.

**Tests** to add to the spec list in Section 6:
- Two-block page: first block renders controls; second block has no controls strip.
- TBD counter increments across blocks: block 1 with one TBD card → `participant_tbd_1`, block 2 with one TBD card → `participant_tbd_2`.
- `team` / `teamRR` page vars are set from block 1's first card and not overwritten by block 2.

## Open questions

None at design stage.

## Decisions log

| Decision | Choice | Reason |
|---|---|---|
| Naked `{{TeamCard}}` runs without columns markers | Bot-edit pages first; wrapper assumes markers always present | Cleaner wrapper; matches existing PrizePool legacy rollout playbook. |
| Module structure | `Module:TeamCard/Legacy` (commons) + per-wiki `Module:TeamCard/Legacy/Custom` | Mirrors PrizePool/Legacy; uniform per-wiki rollout shape. |
| Wiki-template entry points | `columns start`/`TeamCard` stash; `columns end` runs | Mirrors PrizePool/Legacy stash pattern. |
| LPDB storage | Delegate to TP (`Repository.save`); do not call `TeamCard/Storage.saveToLpdb` | TP's record shape is already backwards-compatible with TC (same `objectName`, same legacy participant fields, same qualifier/aliases columns) and additionally merges with prizepool placement records. |
| Multi-team rows (`team2`/`team3`) | TP `contenders` (TBD with `potentialQualifiers`) | Maps to the existing TP semantics for "any of these teams"; matches old TC LPDB behavior (`team='TBD'`) more accurately than aliases would. |
| Team display vs. template | TC `link` (or fallback `team`) → TP `[1]` (template); TC `team` (display name) dropped | TP derives display from team template; old TC's `team` was just a display override and has no TP equivalent. |
| Coach role mapping | `c1` = head coach, others = coach (overridable via `config.coachRoles`) | De-facto convention; per-wiki override available without callback hooks. |
| `pNpos` | Pass through to TP `role` (with optional `config.positionMapping`) | TP's `RoleUtil` normalizes; was wrong to drop. |
| `pNwins` / `pNjoindate` / `pNleavedate` | Pass through to TP `trophies` / `joindate` / `leavedate` | Joindate/leavedate assume the in-flight TP PR has landed. |
| Helper module | None | TP/Repository covers the storage and per-team-vars work; only `team`/`teamRR` global vars need a small backfill, kept inline in `Module:TeamCard/Legacy`. |
| Wiki variables | TP's `setPageVars` covers per-team / per-player / per-staff vars; wrapper only backfills global `team` / `teamRR` | Other modules on the page read those globals. |
| Per-card `disable_storage` / `lpdb_prefix` | Out of scope | TP's `store` is top-level (header-level disable maps to it); TP doesn't have `lpdb_prefix`. Edge cases revisited per-wiki when needed. |
| Wiki customization style | Config table on `Custom`, not callback hooks | Simpler surface; matches Rikard's call. Hooks can be reintroduced if a wiki proves them necessary. |
| Multiple TC blocks per page (groupings) | Wrapper sets `externalControlsRendered` after first block; subsequent blocks reuse the controls strip from the first | Avoids 4× control bars on group-stage pages. Uses TP's existing externalControls coordination, just opts in implicitly. |
