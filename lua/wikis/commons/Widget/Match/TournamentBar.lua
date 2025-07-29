---
-- @Liquipedia
-- page=Module:Widget/Match/TournamentBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Tournament = Lua.import('Module:Tournament')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchTournamentBarProps
---@field match MatchGroupUtilMatch?
---@field displayGameIcon boolean?

---@class MatchTournamentBar: Widget
---@operator call(MatchTournamentBarProps): MatchTournamentBar
---@field props MatchTournamentBarProps
local MatchTournamentBar = Class.new(Widget)

---@return Widget[]|nil
function MatchTournamentBar:render()
	local match = self.props.match
	if not match then
		return
	end

	local tournament = Tournament.partialTournamentFromMatch(match)
	local link = mw.title.makeTitle(0, tournament.pageName, match.section).fullText

	return WidgetUtil.collect(
		self.props.displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'icon-small',
			size = '50px',
		} or nil,
		HtmlWidgets.Span{
			children = {
				LeagueIcon.display{
					icon = tournament.icon,
					iconDark = tournament.iconDark,
					series = tournament.series,
					link = link,
					options = {noTemplate = true},
				}
			}
		},
		HtmlWidgets.Span{
			children = {
				Link{
					link = link,
					children = HtmlWidgets.Span{children = {
						tournament.displayName,
						' - ',
						match.section
					}}
				},
			}
		}
	)
end

return MatchTournamentBar
