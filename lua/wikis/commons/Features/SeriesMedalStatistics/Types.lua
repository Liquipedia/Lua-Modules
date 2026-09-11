---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local SeriesMedalStatisticsTypes = {}

---@class SeriesMedalStatsConditionConfig
---@field series string[]
---@field tier string[]
---@field tierType string[]
---@field startDate string?
---@field endDate string?
---@field additionalConditions string
---@field opponentTypes string[]
---@field columns string[]

---@class SeriesMedalStatsConfig
---@field statsType string
---@field medalsTableType string
---@field cutAfter number
---@field columns string[]
---@field mergeIntoSemifinalists boolean
---@field query SeriesMedalStatsConditionConfig

---@enum SeriesMedalStatisticsTypesOptionalPlacementColumns
SeriesMedalStatisticsTypes.optionalPlacementColumns = {
	THIRD = 3,
	FOURTH = 4,
	SEMIFINALIST = '3-4',
}
---@class SeriesMedalStatsDataSet
---@field [1] number
---@field [2] number
---@field [SeriesMedalStatisticsTypesOptionalPlacementColumns.THIRD] number?
---@field [SeriesMedalStatisticsTypesOptionalPlacementColumns.SEMIFINALIST] number?
---@field [SeriesMedalStatisticsTypesOptionalPlacementColumns.FOURTH] number?
---@field total number

---@enum SeriesMedalStatisticsTypesStatsTypes
SeriesMedalStatisticsTypes.statsTypes = {
	FACTION = 'FACTION',
	PARTICIPANT = 'PARTICIPANT',
	FLAG = 'FLAG',
	PARTICIPANT_TEAM = 'PARTICIPANT_TEAM',
}

---@type table<SeriesMedalStatisticsTypesStatsTypes, {}>
SeriesMedalStatisticsTypes.medalsTableTypes = {
	FACTION =  'Faction',
	PARTICIPANT = 'Participant',
	FLAG = 'Country',
	PARTICIPANT_TEAM = 'Team',
}

return SeriesMedalStatisticsTypes
