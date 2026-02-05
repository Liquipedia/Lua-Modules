---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')

---@class MatchSummaryContainerProps
---@field classes string[]?
---@field width string|integer?
---@field createMatch fun(matchData: MatchGroupUtilMatch): MatchSummaryMatch
---@field match MatchGroupUtilMatch
---@field resetMatch MatchGroupUtilMatch?

---@class MatchSummaryContainer: Widget
---@operator call(MatchSummaryContainerProps): MatchSummaryContainer
---@field props MatchSummaryContainerProps
local MatchSummaryContainer = Class.new(Widget)

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

---@return Widget
function MatchSummaryContainer:render()
	return AnalyticsWidget{
		analyticsName = 'Match popup',
		classes = Array.extend(
			'brkts-popup',
			not self:_hasResetMatch() and 'brkts-popup-container' or nil,
			self.props.classes
		),
		css = {width = self.props.width},
		children = self:_buildChildren(),
	}
end

---@private
---@return boolean
function MatchSummaryContainer:_hasResetMatch()
	return Logic.isNotEmpty(self.props.resetMatch)
end

---@private
---@return Widget|Html
function MatchSummaryContainer:_buildChildren()
	if not self:_hasResetMatch() then
		return self.props.createMatch(self.props.match):create()
	end

	local resetMatch = self.props.resetMatch
	---@cast resetMatch -nil

	---@param matchData MatchGroupUtilMatch
	---@return Widget
	local function createMatchContainer(matchData)
		return HtmlWidgets.Div{
			classes = {'brkts-popup-container'},
			children = self.props.createMatch(matchData):create()
		}
	end

	return ContentSwitch{
		css = {['margin-bottom'] = '0.5rem'},
		tabs = {
			{
				label = MatchSummaryContainer._getExpandedHeader(self.props.match),
				content = createMatchContainer(self.props.match),
			},
			{
				label = MatchSummaryContainer._getExpandedHeader(resetMatch) .. ' Reset',
				content = createMatchContainer(resetMatch),
			},
		},
		size = 'small',
		storeValue = false,
		switchGroup = self.props.match.matchId .. '_resetSelector',
	}
end

return MatchSummaryContainer
