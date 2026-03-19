---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/ListItem
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')
local Title = Lua.import('Module:Widget/Tournament/Title')

---@class TournamentsTickerListItemProps
---@field tournament StandardTournament
---@field displayGameIcon boolean

---@class TournamentsTickerListItemWidget: Widget
---@operator call(TournamentsTickerListItemProps): TournamentsTickerListItemWidget
---@field props TournamentsTickerListItemProps
local TournamentsTickerListItemWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerListItemWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end

	return HtmlWidgets.Div{
		classes = {'tournaments-list-item'},
		children = {
			HtmlWidgets.Div{
				classes = {'tournaments-list-item__title'},
				children = {
					Title{
						tournament = tournament,
						displayGameIcon = self.props.displayGameIcon,
					},
					TierPill{
						tournament = tournament,
						variant = 'subtle',
					},
				},
			},
			HtmlWidgets.Div{
				classes = {'tournaments-list-item__date'},
				children = DateRange{
					startDate = tournament.startDate,
					endDate = tournament.endDate,
				},
			},
		},
	}
end

return TournamentsTickerListItemWidget
