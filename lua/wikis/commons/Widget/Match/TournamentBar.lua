---
-- @Liquipedia
-- page=Module:Widget/Match/TournamentBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local String = Lua.import('Module:StringUtils')
local Tournament = Lua.import('Module:Tournament')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

---@class MatchTournamentBarProps
---@field match MatchGroupUtilMatch?
---@field gameData MatchTickerGameData?
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

	local stageName
	if match.bracketData.inheritedHeader then
		stageName = DisplayHelper.expandHeader(match.bracketData.inheritedHeader)[1]
	end

	local mapIsSet = gameData and not String.isEmpty(gameData.map)

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
					children = HtmlWidgets.Span{
						children = (match.section ~= 'Results' and #match.opponents <= 2 and {
							tournament.displayName,
							' - ',
							match.section
						} or {
							tournament.displayName
						})
					}
				},
				gameData and gameData.gameIds and HtmlWidgets.Span{
					children = WidgetUtil.collect(
						stageName,
						stageName and ' - ' or nil,
						'Game #',
						Array.interleave(gameData.gameIds, '-'),
						mapIsSet and {
							' on ',
							Link{
								link = gameData.map,
								children = gameData.mapDisplayName
							}
						} or nil
					)
				} or nil
			},
			css = {['display'] = 'flex', ['flex-direction'] = 'column'}
		}
	)
end

return MatchTournamentBar
