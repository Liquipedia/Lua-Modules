local FnUtil = require('Module:FnUtil')
local Table = require("Module:Table")

local WikiSpecificBase = {}

-- called from Module:MatchGroup
-- called after processMap/processOpponent/processPlayer
-- used to alter match related parameters, e.g. automatically setting the winner
-- @returns the match after changes have been applied
function WikiSpecificBase.processMatch(frame, match)
	error("This function needs to be implemented on your wiki")
end

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @returns the map after changes have been applied 
function WikiSpecificBase.processMap(frame, map)
	error("This function needs to be implemented on your wiki")
end

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @returns the opponent after changes have been applied
function WikiSpecificBase.processOpponent(frame, opponent)
error("This function needs to be implemented on your wiki")
end

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @returns the player after changes have been applied
function WikiSpecificBase.processPlayer(frame, player)
error("This function needs to be implemented on your wiki")
end

-- called from MatchGroup/Display modules
-- returns true if a MatchSummary shall be shown for this match
function WikiSpecificBase.matchHasDetails(match)
	return match.dateexact or Table.size(match.games) > 0
end

-- called from MatchGroup/Display/Bracket module
-- on wikis this function can be used to automatically get the needed match height, based on the opponent types used in the bracket
-- @returns height
function WikiSpecificBase.get_matchHeight(opponent1, opponent2, height)
	return height
end

--[[
Converts a match record to a structurally typed table with the appropriate data 
types for field values. The match record is either a match created in the store 
bracket codepath (WikiSpecific.processMatch), or a record fetched from LPDB 
(MatchGroupUtil.fetchMatchRecords). 

Called from MatchGroup/Util

-- @returns match
]]
WikiSpecificBase.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	return require('Module:MatchGroup/Util').matchFromRecord
end)

--[[
Returns the module for the matchlist or bracket display modules. The returned 
module must have a luaGet method. 

To customize matchlists and brackets for a wiki, override this to return 
display modules with the wiki-specific customizations.

Called from MatchGroup/Display

-- @returns module
]]
WikiSpecificBase.getMatchGroupModule = function(matchGroupType)
	local LuaUtils = require('Module:LuaUtils')
	local DevFlags = require('Module:DevFlags')
	if matchGroupType == 'matchlist' then
		return DevFlags.matchGroupDev and LuaUtils.lua.requireIfExists('Module:MatchGroup/Display/Matchlist/dev')
			or require('Module:MatchGroup/Display/Matchlist')
	else -- matchGroupType == 'bracket'
		return DevFlags.matchGroupDev and LuaUtils.lua.requireIfExists('Module:MatchGroup/Display/Bracket/dev')
			or require('Module:MatchGroup/Display/Bracket')
	end
end

return WikiSpecificBase
