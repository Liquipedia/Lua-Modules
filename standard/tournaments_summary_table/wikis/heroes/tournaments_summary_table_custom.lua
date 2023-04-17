---
-- @Liquipedia
-- wiki=heroes
-- page=Module:CustomTournamentsSummaryTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local CustomTournamentsSummaryTable = Lua.import('Module:TournamentsSummaryTable', {requireDevIfEnabled = true})

local SECONDS_PER_DAY = 86400

CustomTournamentsSummaryTable.upcomingOffset = SECONDS_PER_DAY * 90
CustomTournamentsSummaryTable.completedOffset = SECONDS_PER_DAY * 90

CustomTournamentsSummaryTable.tiers = {1, 2, 3, 'Qualifier'}
CustomTournamentsSummaryTable.tierTypeExcluded = {'Showmatch'}

return Class.export(CustomTournamentsSummaryTable)
