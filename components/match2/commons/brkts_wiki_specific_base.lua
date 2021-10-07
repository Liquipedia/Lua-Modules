---
-- @Liquipedia
-- wiki=commons
-- page=Module:Brkts/WikiSpecific/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

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
Returns the matchlist or bracket display component. The display component must
be a container, i.e. it takes in a bracket ID rather than a list of matches in
a match group object. See the default implementation (pointed to below) for
details.

To customize matchlists and brackets for a wiki, override this to return
a display component with the wiki-specific customizations.

Called from MatchGroup/Display

-- @returns module
]]
function WikiSpecificBase.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true}).BracketContainer
end

return WikiSpecificBase
