---
-- @Liquipedia
-- page=Module:Widget/Match/TournamentBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Tournament = Lua.import('Module:Tournament')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

---@class MatchTournamentBarProps
---@field match MatchGroupUtilMatch?
---@field gameData MatchTickerGameData?
---@field displayGameIcon boolean?
---@field displayIcon boolean?

local defaultProps = {
	displayIcon = true,
}

---@param props MatchTournamentBarProps
---@return Renderable[]?
local function MatchTournamentBar(props)
	local match = props.match
	local gameData = props.gameData
	if not match then
		return
	end

	local tournament = Tournament.partialTournamentFromMatch(match)
	local tournamentLink = Page.createPageName(0, match.pageName, match.section)

	local stageName
	if match.bracketData.inheritedHeader then
		stageName = DisplayHelper.expandHeader(match.bracketData.inheritedHeader)[1]
	end

	local mapIsSet = gameData and not String.isEmpty(gameData.map)

	return WidgetUtil.collect(
		props.displayIcon and props.displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'icon-small',
			size = '50px',
		} or nil,
		props.displayIcon and Html.Span{
			children = {
				LeagueIcon.display{
					icon = tournament.icon,
					iconDark = tournament.iconDark,
					series = tournament.series,
					link = tournamentLink,
					options = {noTemplate = true},
				}
			}
		} or nil,
		Html.Span{
			classes = {'match-info-tournament-wrapper'},
			children = {
				Html.Span{
					classes = {'match-info-tournament-name'},
					children = {
						Link{
							link = tournamentLink,
							children = Html.Span{
								children = (match.section ~= 'Results' and #match.opponents <= 2 and {
									tournament.displayName,
									' - ',
									match.section
								} or {
									tournament.displayName
								})
							}
						}
					}
				},
				gameData and gameData.gameIds and Html.Span{
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
			}
		}
	)
end

return Component.component(MatchTournamentBar, defaultProps)
