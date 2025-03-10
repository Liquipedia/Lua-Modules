---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings/MatchOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class MatchOverviewWidget: Widget
---@operator call(table): MatchOverviewWidget

local MatchOverviewWidget = Class.new(Widget)

---@return Widget?
function MatchOverviewWidget:render()
	---@type MatchGroupUtilMatch
	local match = self.props.match
	local showOpponent = tonumber(self.props.showOpponent)
	if not match or not showOpponent or #match.opponents < 2 then
		return
	end

	local opponent = match.opponents[showOpponent]
	if not opponent then
		return
	end

	return HtmlWidgets.Div{
		css = {
			['display'] = 'flex',
			['justify-content'] = 'space-between',
			['flex-direction'] = 'column',
			['align-items'] = 'center',
		},
		children = {
			HtmlWidgets.Span{
				children = OpponentDisplay.BlockOpponent{
					opponent = opponent,
					showLink = true,
					overflow = 'ellipsis',
					teamStyle = 'icon',
				}
			},
			HtmlWidgets.Span{
				css = {
					['font-size'] = '0.8em',
				},
				children = match.opponents[1].score .. ' - ' .. match.opponents[2].score,
			},
		},
	}
end

return MatchOverviewWidget
