---
-- @Liquipedia
-- wiki=commons
-- page=Module:Brkts/WikiSpecific/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

---@class BrktsWikiSpecific
---@field defaultIcon string?
local WikiSpecificBase = {}

-- called from Module:MatchGroup
-- used to alter match related parameters, e.g. automatically setting the winner
-- @parameter match - a match
-- @returns the match after changes have been applied
WikiSpecificBase.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom')
	return InputModule and InputModule.processMatch
		or error('Function "processMatch" not implemented on wiki in "Module:MatchGroup/Input/Custom"')
end)

-- called from Module:Match/Subobjects
-- used to transform wiki-specific input of templates to the generalized
-- format that is required by Module:MatchGroup
-- @parameter map - a map
-- @returns the map after changes have been applied
WikiSpecificBase.processMap = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom')
	return InputModule and InputModule.processMap
		or error('Function "processMap" not implemented on wiki in "Module:MatchGroup/Input/Custom"')
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
	local MatchUtil = Lua.import('Module:MatchGroup/Util')
	return MatchUtil.matchFromRecord
end)

--[[
Returns the matchlist or bracket display component. The display component must
be a container, i.e. it takes in a bracket ID rather than a list of matches in
a match group object. See the default implementation (pointed to below) for
details.

To customize matchlists and brackets for a wiki, override this to return
a display component with the wiki-specific customizations.

Called from MatchGroup

-- @returns module
]]
function WikiSpecificBase.getMatchGroupContainer(matchGroupType)
	if matchGroupType == 'matchlist' then
		local MatchList = Lua.import('Module:MatchGroup/Display/Matchlist')
		return MatchList.MatchlistContainer
	end

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket')
	return Bracket.BracketContainer
end

--[[
Returns a display component for single match. The display component must
be a container, i.e. it takes in a match ID rather than a matches.
See the default implementation (pointed to below) for details.

To customize single match display for a wiki, override this to return
a display component with the wiki-specific customizations.

Called from MatchGroup

-- @returns module
]]
function WikiSpecificBase.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		local SingleMatch = Lua.import('Module:MatchGroup/Display/SingleMatch')
		return SingleMatch.SingleMatchContainer
	end

	if displayMode == 'matchpage' then
		-- Single match, displayed on a standalone page
		local MatchPage = Lua.import('Module:MatchGroup/Display/MatchPage')
		return MatchPage.MatchPageContainer
	end
end

return WikiSpecificBase
