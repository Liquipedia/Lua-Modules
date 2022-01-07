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
-- called after processMap/processPlayer
-- used to alter match related parameters, e.g. automatically setting the winner
-- @parameter frame - the frame object
-- @parameter match - a match
-- @returns the match after changes have been applied
WikiSpecificBase.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule and InputModule.processMatch
		or error('Function "processMatch" not implemented on wiki in "Module:MatchGroup/Input/Custom"')
end)

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @parameter frame - the frame object
-- @parameter map - a map
-- @returns the map after changes have been applied
WikiSpecificBase.processMap = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule and InputModule.processMap
		or error('Function "processMap" not implemented on wiki in "Module:MatchGroup/Input/Custom"')
end)

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @parameter frame - the frame object
-- @parameter player - a player
-- @returns the player after changes have been applied
WikiSpecificBase.processPlayer = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule and InputModule.processPlayer
		or error('Function "processPlayer" not implemented on wiki in "Module:MatchGroup/Input/Custom"')
end)

--[[
Converts a match record to a structurally typed table with the appropriate data
types for field values. The match record is either a match created in the store
bracket codepath (WikiSpecific.processMatch), or a record fetched from LPDB
(MatchGroupUtil.fetchMatchRecords).

Called from MatchGroup/Util

-- @returns match
]]
WikiSpecificBase.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	return Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true}).matchFromRecord
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

--[[
Returns a display component for single match. The display component must
be a container, i.e. it takes in a match ID rather than a matches.
See the default implementation (pointed to below) for details.

To customize single match display for a wiki, override this to return
a display component with the wiki-specific customizations.

Called from MatchGroup/Display

-- @returns module
]]
function WikiSpecificBase.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		return Lua.import('Module:MatchGroup/Display/SingleMatch', {requireDevIfEnabled = true}).SingleMatchContainer
	end
end

return WikiSpecificBase
