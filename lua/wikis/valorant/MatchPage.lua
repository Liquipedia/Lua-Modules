---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Table = require('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local WidgetUtil = Lua.import('Module:Widget/Util')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

---@class ValorantMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): ValorantMatchPage
local MatchPage = Class.new(BaseMatchPage)

local AVAILABLE_FOR_TIERS = {1}
local MATCH_PAGE_START_TIME = 1746050400 -- May 1st 2025 midnight
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

local WIN_TYPE_TO_ICON = {
	['elimination'] = 'elimination',
	['explosion'] = 'explosion_valorant',
	['defuse'] = 'defuse',
	['time'] = 'outoftime'
}

---@param match table
---@return boolean
function MatchPage.isEnabledFor(match)
	return Table.includes(AVAILABLE_FOR_TIERS, tonumber(match.liquipediatier))
			and (match.timestamp == DateExt.defaultTimestamp or match.timestamp > MATCH_PAGE_START_TIME)
end

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	-- Update the view model with game and team data
	matchPage:populateGames()

	-- Add more opponent data field
	matchPage:populateOpponents()

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.players = game.opponents[teamIdx].players or {}

			return team
		end)
	end)
end

---@param game MatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderRoundsOverview(game),
			self:_renderPerformance(game)
		)
	}
end

---@private
---@param game MatchPageGame
---@return Widget?
function MatchPage:_renderGameOverview(game)
	if self:isBestOfOne() then return end

	local otherSide = function(side)
		return side == 'atk' and 'def' or 'atk'
	end

	local team1FirstHalf = game.extradata.t1firstside
	local team1OtFirstHalf = game.extradata.t1firstsideot

	local hasStart = team1FirstHalf ~= nil
	local hasOvertime = team1OtFirstHalf ~= nil

	---@param teamIndex 1|2
	---@return {score: number, side: string}[]
	local makeTeamDetails = function(teamIndex)
		local details = {}

		local teamHalf = game.extradata['t' .. teamIndex .. 'halfs']
		if Table.isEmpty(teamHalf) or not hasStart then
			return details
		end

		local firstHalf, startOvertime
		if teamIndex == 1 then
			firstHalf = team1FirstHalf
			startOvertime = team1OtFirstHalf
		else
			firstHalf = otherSide(team1FirstHalf)
			startOvertime = otherSide(team1OtFirstHalf)
		end

		table.insert(details, teamHalf[firstHalf])
		table.insert(details, teamHalf[otherSide(firstHalf)])

		if not hasOvertime then
			return details
		end

		table.insert(details, teamHalf['ot' .. startOvertime])
		table.insert(details, teamHalf['ot' .. otherSide(startOvertime)])

		return details
	end

	local team1 = makeTeamDetails(1)
	local team2 = makeTeamDetails(2)

	local function makeTeamHalfScoreDisplay(half)
		return Div{
			classes = {
				'match-bm-game-summary-team-halves-half',
				'match-bm-game-summary-team-halves-half--' .. half.side
			},
			children = half.score
		}
	end

	local function makeTeamHalvesDisplay(halves)
		return Div{
			classes = {
				'match-bm-game-summary-team-halves',
			},
			children = Array.interleave(Array.map(halves, function(half)
				return makeTeamHalfScoreDisplay(half)
			end), SPAN_SLASH)
		}
	end

	return Div{
		classes = {'match-bm-lol-game-overview'},
		children = {
			Div{
				classes = {'match-bm-lol-game-summary'},
				children = {
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = {
							self.opponents[1].iconDisplay,
							makeTeamHalvesDisplay(team1)
						}
					},
					Div{
						classes = {'match-bm-lol-game-summary-score-holder'},
						children = game.finished and {
							Div{
								classes = {'match-bm-lol-game-summary-score'},
								children = {
									DisplayHelper.MapScore(game.opponents[1], game.status),
									'&#8209;', -- Non-breaking hyphen
									DisplayHelper.MapScore(game.opponents[2], game.status)
							}
							},
							Div{
								classes = {'match-bm-lol-game-summary-length'},
								children = game.length
							}
						} or nil
					},
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = {
							self.opponents[2].iconDisplay,
							makeTeamHalvesDisplay(team2)
						}
					},
				}
			}
		}
	}
end

---@private
---@param game MatchPageGame
---@return Widget
function MatchPage:_renderRoundsOverview(game)
	return RoundsOverview{
		rounds = game.extradata.rounds,
		opponent1 = self.matchData.opponents[1],
		opponent2 = self.matchData.opponents[2],
		iconRender = function(winningSide, winBy)
			local iconName = WIN_TYPE_TO_ICON[winBy]
			if not iconName then
				return nil
			end
			return IconFa{
				iconName = iconName,
				additionalClasses = {
					'match-bm-rounds-overview-round-outcome-icon',
					'match-bm-rounds-overview-round-outcome-icon--' .. winningSide
				}
			}
		end,
	}
end

---@private
---@param game MatchPageGame
---@return Widget[]
function MatchPage:_renderPerformance(game)
	return {
		HtmlWidgets.H3{children = 'Player Performance'},
		Div{
			classes = {'match-bm-players-wrapper'},
			children = {
				self:_renderPerformanceForTeam(game, 1),
				self:_renderPerformanceForTeam(game, 2)
			}
		}
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderPerformanceForTeam(game, teamIndex)
	return Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-players-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Array.map(game.teams[teamIndex].players, function (player)
				return self:_renderPlayerPerformance(game, teamIndex, player)
			end)
		)
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@param player table
---@return Widget
function MatchPage:_renderPlayerPerformance(game, teamIndex, player)
	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-2'},
		children = {
			PlayerDisplay{
				characterIcon = self:getCharacterIcon(player.agent),
				characterName = player.character,
				playerName = player.displayName or player.player,
				playerLink = player.player,
			},
			Div{
				classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-5'},
				children = {
					PlayerStat{
						title = {IconFa{iconName = 'acs'}, 'ACS'},
						data = MathUtil.round(player.acs)
					},
					PlayerStat{
						title = {IconFa{iconName = 'kda'}, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {IconFa{iconName = 'kast'}, 'KAST'},
						data = player.kast and (player.kast .. '%') or nil
					},
					PlayerStat{
						title = {IconFa{iconName = 'damage'}, 'ADR'},
						data = player.adr
					},
					PlayerStat{
						title = {IconFa{iconName = 'headshot'}, 'HS%'},
						data = player.hs and (player.hs .. '%') or nil
					}
				}
			}
		}
	}
end

return MatchPage
