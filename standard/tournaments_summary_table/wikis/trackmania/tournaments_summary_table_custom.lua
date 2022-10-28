---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:CustomTournamentsSummaryTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local _SECONDS_PER_DAY = 86400

local CustomTournamentsSummaryTable = Lua.import('Module:TournamentsSummaryTable', { requireDevIfEnabled = true })

CustomTournamentsSummaryTable.upcomingOffset = _SECONDS_PER_DAY * 30
CustomTournamentsSummaryTable.completedOffset = _SECONDS_PER_DAY * 90

CustomTournamentsSummaryTable.tiers = { 1, 2, 3 }
CustomTournamentsSummaryTable.defaultLimit = 10
CustomTournamentsSummaryTable.tierTypeExcluded = {
	'Campaign',
	'Misc',
	'Weekly',
	'Show Match',
	'Qualifier'
}

return Class.export(CustomTournamentsSummaryTable)
