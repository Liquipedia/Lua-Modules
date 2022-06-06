---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:CustomTournamentsSummaryTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local CustomTournamentsSummaryTable = require('Module:TournamentsSummaryTable')

CustomTournamentsSummaryTable.tiers = {1, 2, 3}
CustomTournamentsSummaryTable.defaultLimit = 9

return Class.export(CustomTournamentsSummaryTable)
