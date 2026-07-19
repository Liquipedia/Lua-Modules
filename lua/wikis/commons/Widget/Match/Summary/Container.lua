---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')

---@class MatchSummaryContainerProps
---@field classes string[]?
---@field width string|integer?
---@field createMatch fun(matchData: MatchGroupUtilMatch): MatchSummaryMatch
---@field match MatchGroupUtilMatch
---@field resetMatch MatchGroupUtilMatch?

local MatchSummaryContainer = {}

---@private
---@param matchData MatchGroupUtilMatch
---@return string?
function MatchSummaryContainer._getExpandedHeader(matchData)
	local bracketData = matchData.bracketData
	local header = bracketData.header or bracketData.inheritedHeader --[[@as string]]
	if Logic.isEmpty(header) then
		return
	end
	return DisplayHelper.expandHeader(header)[1]
end

---@param props MatchSummaryContainerProps
---@return VNode
function MatchSummaryContainer.render(props)
	return AnalyticsWidget{
		analyticsName = 'Match popup',
		classes = Array.extend(
			'brkts-popup',
			not MatchSummaryContainer._hasResetMatch(props) and 'brkts-popup-container' or nil,
			props.classes
		),
		css = {width = props.width},
		children = MatchSummaryContainer._buildChildren(props),
	}
end

---@private
---@param props MatchSummaryContainerProps
---@return boolean
function MatchSummaryContainer._hasResetMatch(props)
	return Logic.isNotEmpty(props.resetMatch)
end

---@private
---@param props MatchSummaryContainerProps
---@return Renderable
function MatchSummaryContainer._buildChildren(props)
	if not MatchSummaryContainer._hasResetMatch(props) then
		return props.createMatch(props.match):create()
	end

	local resetMatch = props.resetMatch
	---@cast resetMatch -nil

	---@param matchData MatchGroupUtilMatch
	---@return VNode
	local function createMatchContainer(matchData)
		return Html.Div{
			classes = {'brkts-popup-container'},
			children = props.createMatch(matchData):create()
		}
	end

	return ContentSwitch{
		css = {['margin-bottom'] = '0.5rem'},
		tabs = {
			{
				label = MatchSummaryContainer._getExpandedHeader(props.match),
				content = createMatchContainer(props.match),
			},
			{
				label = MatchSummaryContainer._getExpandedHeader(resetMatch) .. ' Reset',
				content = createMatchContainer(resetMatch),
			},
		},
		storeValue = false,
		switchGroup = props.match.matchId .. '_resetSelector',
	}
end

return Component.component(MatchSummaryContainer.render)
