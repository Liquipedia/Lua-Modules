---
-- @Liquipedia
-- page=Module:Widget/Match/Page/SeriesDots
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Label = Lua.import('Module:Widget/Basic/Label')

---@class MatchPageSeriesDotsParameters
---@field seriesDots string[]?

local RESULT_DISPLAY_TYPES = {
	['w'] = 'win',
	['l'] = 'loss',
	['winner'] = 'win',
	['loser'] = 'loss',
	['-'] = 'default'
}

---@param result string
---@return VNode
local makeGameResultIcon = FnUtil.memoize(function (result)
	return Label{labelType = 'result-' .. RESULT_DISPLAY_TYPES[result:lower()]}
end)

---@param props {seriesDots: string[]?}
---@return Widget?
local function MatchPageSeriesDots(props)
	local seriesDots = props.seriesDots
	if Logic.isEmpty(seriesDots) then
		return
	end

	---@cast seriesDots -nil

	return Div{
		classes = {'match-bm-match-header-round-results'},
		children = Array.map(seriesDots, makeGameResultIcon)
	}
end

return Component.component(MatchPageSeriesDots)
