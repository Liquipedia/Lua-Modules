---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/TournamentInfo
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Game = Lua.import('Module:Game')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Tournament = Lua.import('Module:Tournament')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@alias MatchTickerTournamentInfoProps MatchTickerCardProps

local MatchTickerTournamentInfo = {}

---@param tournament StandardTournamentPartial
---@param link string
---@param displayIcon boolean?
---@param displayGameIcon boolean?
---@return Renderable[]?
function MatchTickerTournamentInfo.buildTournamentIcons(tournament, link, displayIcon, displayGameIcon)
	if not displayIcon then
		return
	end
	return WidgetUtil.collect(
		displayGameIcon and Game.icon{
			game = tournament.game,
			noLink = true,
			spanClass = 'icon-small',
			size = '50px',
		} or nil,
		Html.Span{
			children = LeagueIcon.display{
				icon = tournament.icon,
				iconDark = tournament.iconDark,
				series = tournament.series,
				link = link,
				options = {noTemplate = true},
			}
		}
	)
end

---@param tournament StandardTournamentPartial
---@param link string
function MatchTickerTournamentInfo.buildTournamentDisplay(tournament, link)
	return Html.Span{
		classes = {'match-ticker-card-tournament-name'},
		children = Link{
			link = link,
			children = tournament.displayName
		}
	}
end

---@param match MatchGroupUtilMatch
---@param gameData MatchTickerGameData?
---@return VNode?
function MatchTickerTournamentInfo.buildGameDataDisplay(match, gameData)
	if not gameData or not gameData.gameIds then
		return
	end
	local stageName
	if match.bracketData.inheritedHeader then
		stageName = DisplayHelper.expandHeader(match.bracketData.inheritedHeader)[1]
	end
	return Html.Span{
		classes = {'match-ticker-card-tournament-game'},
		children = WidgetUtil.collect(
			stageName,
			stageName and ' - ' or nil,
			'Game #',
			Array.interleave(gameData.gameIds, '-'),
			not String.isEmpty(gameData.map) and {
				' on ',
				Link{
					link = gameData.map,
					children = gameData.mapDisplayName
				}
			} or nil
		)
	}
end

---@param props MatchTickerTournamentInfoProps
---@return VNode?
function MatchTickerTournamentInfo.render(props)
	local match = props.match
	if props.hideTournament and #match.opponents <= 2 then
		return
	end
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = props.onlyHighlightOnValue})

	local tournament = Tournament.partialTournamentFromMatch(match)
	local tournamentLink = Page.createPageName(0, match.pageName, match.section)

	return Html.Div{
		classes = {
			'match-ticker-card-tournament',
			highlight and HIGHLIGHT_CLASS or nil
		},
		children = WidgetUtil.collect(
			MatchTickerTournamentInfo.buildTournamentIcons(
				tournament, tournamentLink, not props.hideTournament, props.displayGameIcons
			),
			Html.Span{
				classes = {'match-ticker-card-tournament-wrapper'},
				children = WidgetUtil.collect(
					not props.hideTournament and MatchTickerTournamentInfo.buildTournamentDisplay(
						tournament, tournamentLink
					) or nil,
					MatchTickerTournamentInfo.buildGameDataDisplay(match, props.gameData)
				)
			}
		)
	}
end

return Component.component(MatchTickerTournamentInfo.render)
