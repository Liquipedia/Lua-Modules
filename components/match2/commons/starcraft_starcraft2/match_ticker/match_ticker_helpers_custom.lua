---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker/Helpers/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Logic = require('Module:Logic')

local CustomHelperFunctions = Lua.import('Module:MatchTicker/Helpers', {requireDevIfEnabled = true})

CustomHelperFunctions.featuredClass = 'sc2premier-highlighted'
CustomHelperFunctions.isFeatured = function(matchData)
	return Logic.readBool((matchData.extradata or {}).featured)
end
CustomHelperFunctions.tbdIdentifier = 'definitions'
CustomHelperFunctions.OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
CustomHelperFunctions.Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

return CustomHelperFunctions
