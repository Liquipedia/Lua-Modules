---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Tournament/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local Link = Lua.import('Module:Widget/Basic/Link')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')

---@class TournamentsTickerWidget: Widget
---@operator call(table): TournamentsTickerWidget

local TournamentsTickerWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerWidget:render()
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
					['flex-grow'] = '1',
					['padding-left'] = '25px',
				},
				children = {
					self.props.displayGameIcon and Game.icon{
						game = tournament.game,
					} or '',
					LeagueIcon.display {
						icon = tournament.icon,
						iconDark = tournament.iconDark,
						series = tournament.series,
						abbreviation = tournament.abbreviation,
						link = tournament.pageName,
					},
					Link{
						link = tournament.pageName,
						children = tournament.displayName,
					},
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

return TournamentsTickerWidget
