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
---@field gameData MatchGroupUtilGameData?
---@field displayGameIcon boolean?

---@class MatchTournamentBar: Widget
---@operator call(MatchTournamentBarProps): MatchTournamentBar
---@field props MatchTournamentBarProps
local MatchTournamentBar = Class.new(Widget)

---@return Widget[]|nil
function MatchTournamentBar:render()
	local match = self.props.match
	local gameData = self.props.gameData
	if not match then
		return
	end

	local tournament = Tournament.partialTournamentFromMatch(match)
	local tournamentLink = mw.title.makeTitle(0, match.pageName, match.section).fullText
	local mapLink = mw.title.makeTitle(0, match.pageName, gameData.map).fullText

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
					link = tournamentLink,
					options = {noTemplate = true},
				}
			}
		},
		HtmlWidgets.Span{
			children = {
				Link{
					link = tournamentLink,
					children = HtmlWidgets.Span{children = {
						tournament.displayName,
						children = match.section ~= "Results" and {
							' - ',
							match.section,
						} or nil
					}}
				},
				#match.opponents > 2 and HtmlWidgets.Span{
					children = HtmlWidgets.Span{children = {
						match.bracketData.title,
						' - ',
						gameData.gameIds
						' on ',
						Link{
							link = mapLink,
							children = HtmlWidgets.Span{
								gameData.mapDisplayName
							}
						},
					}}
				} or nil
			}
		}
	)
end

return MatchTournamentBar
