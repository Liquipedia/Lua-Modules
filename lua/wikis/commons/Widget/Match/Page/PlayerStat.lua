---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerStat
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPagePlayerStatParameters
---@field title (string|Html|Widget|nil)|(string|Html|Widget|nil)[]
---@field data (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPagePlayerStat: Widget
---@operator call(MatchPagePlayerStatParameters): MatchPagePlayerStat
---@field props MatchPagePlayerStatParameters
local MatchPagePlayerStat = Class.new(Widget)

---@return Widget
function MatchPagePlayerStat:render()
	local title = self.props.title
	local data = self.props.data
	assert(Logic.isNotEmpty(title), 'Title not specified for this stat')
	data = Logic.emptyOr(data, '?')
	return {
		Div{
			classes = { 'match-bm-players-player-stat' },
			children = {
				Div{
					classes = {'match-bm-players-player-stat-title'},
					children = WidgetUtil.collect(title)
				},
				Div{
					classes = {'match-bm-players-player-stat-data'},
					children = WidgetUtil.collect(data)
				}
			}
		}
	}
end

return MatchPagePlayerStat
