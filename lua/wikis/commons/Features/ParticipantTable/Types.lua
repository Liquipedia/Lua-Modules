---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Types = {}

---@class ParticipantsTableEntryProps
---@field opponent standardOpponent
---@field note string?
---@field dq boolean?
---@field config ParticipantTableConfig
---@field additionalProps table?
---@field useDefaultWidth boolean?

---@class ParticipantTableConfig
---@field lpdbPrefix string?
---@field noStorage boolean
---@field matchGroupSpec MatchGroupsSpec?
---@field syncPlayers boolean
---@field showCountBySection boolean
---@field onlyNotable boolean
---@field count number?
---@field colSpan number
---@field resolveDate string
---@field sortPlayers boolean sort players within an opponent
---@field sortOpponents boolean
---@field showTeams boolean
---@field title string?
---@field importOnlyQualified boolean?
---@field display boolean
---@field width string
---@field columnWidth string
---@field showTitle boolean only applies for the title of the whole table
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field displayMultipleFactionColumn boolean?
---@field isRandomEvent boolean?
---@field manualFactionCounts table<string, number?>
---@field factionColumnWidth number
---@field soloAsFactionTable boolean?

---@class ParticipantTableSection
---@field config ParticipantTableConfig
---@field entries ParticipantTableEntry[]

---@class ParticipantTableEntry
---@field opponent standardOpponent
---@field name string
---@field note string?
---@field dq boolean
---@field isResolved boolean?
---@field sortName string
---@field seed integer?

return Types
