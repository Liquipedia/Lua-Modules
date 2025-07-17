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
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentTitleWidget: Widget
---@operator call(table): TournamentTitleWidget
local TournamentTitleWidget = Class.new(Widget)

---@return Widget?
function TournamentTitleWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end

	local hasStageName = Logic.isNotEmpty(self.props.stageName)

	return Link{
		link = tournament.pageName,
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
						options = {noTemplate = true, noLink = true},
					}
				}
			},
			HtmlWidgets.Span{
				classes = {'tournament-name'},
				children = {
					children = {
						tournament.displayName,
						hasStageName and ' - ' or nil,
						hasStageName and self.props.stageName or nil,
					},
				}
			}
		},
	}
end

return TournamentTitleWidget
