---
-- @Liquipedia
-- page=Module:Widget/Match/Page/SeriesDots
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageSeriesDotsParameters
---@field seriesDots string[]?

local RESULT_DISPLAY_TYPES = {
	['w'] = 'winner',
	['l'] = 'loser',
	['winner'] = 'winner',
	['loser'] = 'loser',
	['-'] = 'notplayed'
}

---@class MatchPageSeriesDots: Widget
---@operator call(MatchPageSeriesDotsParameters): MatchPageSeriesDots
---@field props MatchPageSeriesDotsParameters
local MatchPageSeriesDots = Class.new(Widget)

---@private
---@param result string
---@return Widget
function MatchPageSeriesDots._makeGameResultIcon(result)
	return Div{
		classes = { 'match-bm-match-header-round-result', 'result--' .. RESULT_DISPLAY_TYPES[result:lower()] }
	}
end

---@return Widget?
function MatchPageSeriesDots:render()
	local seriesDots = self.props.seriesDots
	if Logic.isEmpty(seriesDots) then
		return
	end

	---@cast seriesDots -nil

	return Div{
		classes = { 'match-bm-match-header-round-results' },
		children = Array.map(seriesDots, MatchPageSeriesDots._makeGameResultIcon)
	}
end

return MatchPageSeriesDots
