---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/ListItem
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')

---@class TournamentsTickerListItemProps
---@field tournament StandardTournament
---@field displayGameIcon boolean
---@field tierColorScheme string?

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

	local hasIcon = not Logic.isEmpty(tournament.icon) or not Logic.isEmpty(tournament.iconDark)
	local iconWidget = hasIcon
		and LeagueIcon.display{
			icon = tournament.icon,
			iconDark = tournament.iconDark,
			series = tournament.series,
			link = tournament.pageName,
			options = {noTemplate = true},
		}
		or Icon{iconName = 'firstplace', size = '1.125rem'}

	local badgeChildren = {
		HtmlWidgets.Span{
			classes = {'tournaments-list-item__icon-compact'},
			children = iconWidget,
		},
	}
	if self.props.displayGameIcon then
		table.insert(badgeChildren, HtmlWidgets.Div{
			classes = {'tournaments-list-item__game-icon'},
			children = Game.icon{
				game = tournament.game,
				noLink = true,
				size = '16px',
			},
		})
	end
	table.insert(badgeChildren, TierPill{
		tournament = tournament,
		variant = 'subtle',
		colorScheme = self.props.tierColorScheme,
	})

	return HtmlWidgets.Div{
		classes = {'tournaments-list-item'},
		children = {
			HtmlWidgets.Span{
				classes = {'tournament-icon'},
				children = iconWidget,
			},
			HtmlWidgets.Div{
				classes = {'tournaments-list-item__content'},
				children = {
					HtmlWidgets.Div{
						classes = {'tournaments-list-item__name'},
						children = Link{
							link = tournament.pageName,
							children = tournament.displayName,
						},
					},
					HtmlWidgets.Div{
						classes = {'tournaments-list-item__meta'},
						children = {
							HtmlWidgets.Div{
								classes = {'tournaments-list-item__badges'},
								children = badgeChildren,
							},
							HtmlWidgets.Div{
								classes = {'tournaments-list-item__date'},
								children = DateRange{
									startDate = tournament.startDate,
									endDate = tournament.endDate,
								},
							},
						},
					},
				},
			},
		},
	}
end

return TournamentsTickerListItemWidget
