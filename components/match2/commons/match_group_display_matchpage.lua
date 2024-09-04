---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local WikiSpecific = Lua.import('Module:Brkts/WikiSpecific')

local MatchPageDisplay = {}

---@class MatchPageConfigOptions
---@field MatchPageContainer function?

---Display component for a MatchPAge. The MatchPage is specified by matchID.
---The component fetches the match data from LPDB or page variables.
---@param props {matchId: string, config: MatchPageConfigOptions}
---@return Html
function MatchPageDisplay.MatchPageContainer(props)
	local bracketId, _ = MatchGroupUtil.splitMatchId(props.matchId)

	assert(bracketId, 'Missing or invalid matchId')

	local matchRecord = MatchGroupUtil.fetchMatchRecords(bracketId)[1]
	assert(matchRecord, 'Could not find match record')
	local match = WikiSpecific.matchFromRecord(matchRecord)
	return MatchPageDisplay.SingleMatch{
			config = props.config,
			match = match,
		}
end

---Display component for a singleMatch. Match data is specified in the input.
---@param props {config: MatchPageConfigOptions, match: MatchGroupUtilMatch}
---@return Html
function MatchPageDisplay.SingleMatch(props)
	local propsConfig = props.config or {}
	local config = {
		MatchPageContainer = propsConfig.MatchPageContainer or DisplayHelper.DefaultMatchPageContainer,
	}

	return MatchPageDisplay.Match{
		MatchPageContainer = config.MatchPageContainer,
		match = props.match,
	}
end

---Display component for a matcch. Consists of the match page.
---@param props {MatchPageContainer: function, match: MatchGroupUtilMatch}
---@return Html
function MatchPageDisplay.Match(props)
	local bracketId = MatchGroupUtil.splitMatchId(props.match.matchId)

	return DisplayUtil.TryPureComponent(props.MatchPageContainer, {
		bracketId = bracketId,
		matchId = props.match.matchId,
		config = {showScore = true},
		match = props.match,
	}, require('Module:Error/Display').ErrorList)
end

return Class.export(MatchPageDisplay)
