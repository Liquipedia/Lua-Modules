---
-- @Liquipedia
-- page=Module:Widget/Tournament/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentsTickerTitleWidget: Widget
---@operator call(table): TournamentsTickerTitleWidget
local TournamentsTickerTitleWidget = Class.new(Widget)

---@return Widget?
function TournamentsTickerTitleWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end
	return HtmlWidgets.Fragment{
		children = {
			self.props.displayGameIcon and Game.icon{
				game = tournament.game,
				noLink = true,
				spanClass = 'tournament-game-icon icon-small',
				size = '50px',
			} or '',
			HtmlWidgets.Span{
				classes = {'tournament-icon'},
				children = {
					LeagueIcon.display{
						icon = tournament.icon,
						iconDark = tournament.iconDark,
						series = tournament.series,
						abbreviation = tournament.abbreviation,
						link = tournament.pageName,
						options = {noTemplate = true},
					}
				}
			},
			HtmlWidgets.Span{
				classes = {'tournament-name'},
				children = {
					Link{
						link = tournament.pageName,
						children = tournament.displayName,
					},
				}
			}
		},
	}
end

return TournamentsTickerTitleWidget
