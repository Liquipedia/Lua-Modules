---
-- @Liquipedia
-- page=Module:Widget/Tournament/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local Link = Lua.import('Module:Widget/Basic/Link')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')
local Title = Lua.import('Module:Widget/Tournament/Title')

---@class TournamentsTickerLabelWidget: Widget
---@operator call(table): TournamentsTickerLabelWidget
local TournamentsTickerLabelWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerLabelWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end
	return HtmlWidgets.Div{
		css = {
			display = 'flex',
			gap = '5px',
			['margin-top'] = '0.3em',
			['margin-left'] = '10px',
		},
		children = {
			TierPill{tournament = tournament},
			HtmlWidgets.Span{
				classes = {'tournaments-list-name'},
				css = {
					['padding-left'] = self.props.displayGameIcon and '50px' or '25px',
				},
				children = {
					Title{
						tournament = tournament,
						displayGameIcon = self.props.displayGameIcon
					}
				},
			},
			HtmlWidgets.Small{
				classes = {'tournaments-list-dates'},
				css = {
					['flex-shrink'] = '0',
				},
				children = Link{
					children = DateRange{startDate = tournament.startDate, endDate = tournament.endDate},
					link = tournament.pageName
				},
			},
		},
	}
end

return TournamentsTickerLabelWidget
