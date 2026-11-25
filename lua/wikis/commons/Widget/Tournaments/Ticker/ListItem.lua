---
-- @Liquipedia
-- page=Module:Widget/Tournaments/Ticker/ListItem
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local DateRange = Lua.import('Module:Widget/Misc/DateRange')
local Link = Lua.import('Module:Widget/Basic/Link')
local TierPill = Lua.import('Module:Widget/Tournament/TierPill')

---@class TournamentsTickerListItemProps
---@field tournament StandardTournament
---@field displayGameIcon boolean?
---@field tierColorScheme string?

---@param props TournamentsTickerListItemProps
---@return VNode?
local function TournamentsTickerListItem(props)
	local tournament = props.tournament
	if not tournament then
		return
	end

	local iconWidget = LeagueIcon.display{
		icon = tournament.icon,
		iconDark = tournament.iconDark,
		series = tournament.series,
		link = tournament.pageName,
		options = {noTemplate = true},
	}

	local badgeChildren = WidgetUtil.collect(
		Html.Span{
			classes = {'tournaments-list-item__badge-icon'},
			children = iconWidget,
		},
		props.displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'tournaments-list-item__game-icon',
		} or nil,
		TierPill{
			tournament = tournament,
			variant = 'subtle',
			colorScheme = props.tierColorScheme,
		}
	)

	return Html.Div{
		classes = {'tournaments-list-item'},
		children = {
			Html.Span{
				classes = {'tournament-icon'},
				children = iconWidget,
			},
			Html.Div{
				classes = {'tournaments-list-item__content'},
				children = {
					Html.Div{
						classes = {'tournaments-list-item__name'},
						children = Link{
							link = tournament.pageName,
							children = tournament.displayName,
						},
					},
					Html.Div{
						classes = {'tournaments-list-item__meta'},
						children = {
							Html.Div{
								classes = {'tournaments-list-item__badges'},
								children = badgeChildren,
							},
							Html.Div{
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

return Component.component(TournamentsTickerListItem)
