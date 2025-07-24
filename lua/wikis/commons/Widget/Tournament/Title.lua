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
local String = Lua.import('Module:StringUtils')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentTitleProps
---@field tournament StandardTournamentPartial
---@field stageName string?
---@field displayGameIcon boolean?

---@class TournamentTitleWidget: Widget
---@operator call(TournamentTitleProps): TournamentTitleWidget
---@field props TournamentTitleProps
local TournamentTitleWidget = Class.new(Widget)

---@return Widget?
function TournamentTitleWidget:render()
	local tournament = self.props.tournament
	if not tournament then
		return
	end

	local hasStage = self.props.stageName ~= nil and not String.contains(self.props.stageName, 'Results')

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		self.props.displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'tournament-game-icon icon-small',
			size = '50px',
		} or nil,
		HtmlWidgets.Span{
			classes = {'tournament-icon'},
			children = {
				LeagueIcon.display{
					icon = tournament.icon,
					iconDark = tournament.iconDark,
					series = tournament.series,
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
					children = HtmlWidgets.Fragment{children = {
						tournament.displayName,
						hasStage and ' - ' or nil,
						hasStage and self.props.stageName or nil
					}}
				},
			}
		}
	)}
end

return TournamentTitleWidget
