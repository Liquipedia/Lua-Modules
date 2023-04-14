---
-- @Liquipedia
-- wiki=heroes
-- page=Module:CustomTournamentsSummaryTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomTournamentsSummaryTable = require('Module:TournamentsSummaryTable')

local _SECONDS_PER_DAY = 86400

CustomTournamentsSummaryTable.upcomingOffset = _SECONDS_PER_DAY * 30
CustomTournamentsSummaryTable.completedOffset = _SECONDS_PER_DAY * 30

CustomTournamentsSummaryTable.tiers = {1, 2, 3, 'Qualifier'}
CustomTournamentsSummaryTable.tierTypeExcluded = {'Showmatch'}

return Class.export(CustomTournamentsSummaryTable)
