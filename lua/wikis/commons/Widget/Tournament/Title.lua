---
-- @Liquipedia
-- page=Module:Widget/Tournament/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class TournamentTitleProps
---@field tournament StandardTournamentPartial
---@field displayGameIcon boolean?
---@field useShortName boolean?

---@param props TournamentTitleProps
---@return Renderable[]?
local function TournamentTitle(props)
	local tournament = props.tournament
	if not tournament then
		return
	end

	return WidgetUtil.collect(
		props.displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'tournament-game-icon icon-small',
			size = '50px',
		} or nil,
		Html.Span{
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
		Html.Span{
			classes = {'tournament-name'},
			children = {
				Link{
					link = tournament.pageName,
					children = Logic.readBool(props.useShortName) and tournament.shortName or tournament.displayName,
				},
			}
		}
	)
end

return Component.component(TournamentTitle)
