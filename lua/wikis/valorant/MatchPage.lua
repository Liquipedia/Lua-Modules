---
-- @Liquipedia
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local WidgetUtil = Lua.import('Module:Widget/Util')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

---@class ValorantMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): ValorantMatchPage
local MatchPage = Class.new(BaseMatchPage)

local CREDS_ICON = AutoInlineIcon.display{onlyicon = true, category = 'M', lookup = 'creds'}
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

local ROUNDS_BEFORE_SPLIT = 12
local WIN_TYPE_TO_ICON = {
	['elimination'] = 'elimination',
	['detonate'] = 'explosion_valorant',
	['defuse'] = 'defuse',
	['time'] = 'outoftime'
}

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
			local rounds = game.extradata.rounds --[[ @as ValorantRoundData[] ]]
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.players = Array.filter(game.opponents[teamIdx].players or {}, Table.isNotEmpty)

			team.thrifties = #Array.filter(rounds, function (round)
				return round['t' .. teamIdx .. 'side'] == round.winningSide and round.ceremony == 'Thrifty'
			end)

			team.clutches = #Array.filter(rounds, function (round)
				return round['t' .. teamIdx .. 'side'] == round.winningSide and round.ceremony == 'Clutch'
			end)

			local plantedRounds = Array.filter(rounds, function (round)
				return round['t' .. teamIdx .. 'side'] == 'atk' and round.planted
			end)

			team.postPlant = {
				#Array.filter(plantedRounds, function (round)
					return round.winningSide == 'atk'
				end),
				#plantedRounds
			}

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
			self:_renderTeamStats(game),
			self:_renderPerformance(game)
		)
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex 1|2
---@return {score: number, side: string}[]
local function getTeamHalvesDetails(game, teamIndex)
	if not teamIndex or not game.extradata then
		return {}
	end

	local otherSide = function(side)
		return side == 'atk' and 'def' or 'atk'
	end

	local startNormal, otherNormal = game.extradata.t1firstside, otherSide(game.extradata.t1firstside)
	local startOvertime, otherOvertime = game.extradata.t1firstsideot, otherSide(game.extradata.t1firstsideot)

	if not startNormal or not otherNormal then
		return {}
	end

	if teamIndex == 2 then
		startNormal, otherNormal, startOvertime, otherOvertime = otherNormal, startNormal, otherOvertime, startOvertime
	end

	local teamHalf = game.extradata['t' .. teamIndex .. 'halfs']
	if Table.isEmpty(teamHalf) then
		return {}
	elseif not startOvertime or not otherOvertime then
		return {
			{side = startNormal, score = teamHalf[startNormal]},
			{side = otherNormal, score = teamHalf[otherNormal]},
		}
	end

	---@type {score: number, side: string}[]
	return {
		{side = startNormal, score = teamHalf[startNormal]},
		{side = otherNormal, score = teamHalf[otherNormal]},
		{side = startOvertime, score = teamHalf['ot' .. startOvertime]},
		{side = otherOvertime, score = teamHalf['ot' .. otherOvertime]},
	}
end

---@private
---@param game MatchPageGame
---@return Widget|Widget[]
function MatchPage:_renderGameOverview(game)
	local team1 = getTeamHalvesDetails(game, 1)
	local team2 = getTeamHalvesDetails(game, 2)

	local function makeTeamHalvesDisplay(halves)
		return Div{
			classes = {
				'match-bm-game-summary-team-halves',
			},
			children = Array.interleave(Array.map(halves, function(half)
				return Div{
					classes = {
						'match-bm-game-summary-team-halves-half',
						'match-bm-game-summary-team-halves-half--' .. half.side
					},
					children = half.score
				}
			end), SPAN_SLASH)
		}
	end

	---@param showScore boolean
	---@return Widget[]
	local function createScoreHolderContent(showScore)
		local mapDisplay = Div{
			classes = {'match-bm-lol-game-summary-map'},
			children = game.map
		}
		local lengthDisplay = Div{
			classes = {'match-bm-lol-game-summary-length'},
			children = game.length
		}
		if showScore then
			return {
				Div{
					classes = {'match-bm-lol-game-summary-score'},
					children = {
						DisplayHelper.MapScore(game.opponents[1], game.status),
						'&#8209;', -- Non-breaking hyphen
						DisplayHelper.MapScore(game.opponents[2], game.status)
					}
				},
				mapDisplay,
				lengthDisplay
			}
		end
		return {mapDisplay, lengthDisplay}
	end

	local overview = Div{
		classes = {'match-bm-lol-game-overview'},
		children = {
			Div{
				classes = {'match-bm-lol-game-summary'},
				children = {
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = {
							makeTeamHalvesDisplay(team1),
							self.opponents[1].iconDisplay,
						}
					},
					Div{
						classes = {'match-bm-lol-game-summary-score-holder'},
						children = MatchGroupUtil.computeMatchPhase(game) ~= 'upcoming'
							and createScoreHolderContent(not self:isBestOfOne()) or nil
					},
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = {
							self.opponents[2].iconDisplay,
							makeTeamHalvesDisplay(team2),
						}
					},
				}
			}
		}
	}

	if self:isBestOfOne() then
		return {
			HtmlWidgets.H3{children = {'Game Overview: ', game.map}},
			overview
		}
	end
	return overview
end

---@private
---@param game MatchPageGame
---@return Widget
function MatchPage:_renderRoundsOverview(game)
	return RoundsOverview{
		rounds = game.extradata.rounds,
		roundsPerHalf = ROUNDS_BEFORE_SPLIT,
		opponent1 = self.matchData.opponents[1],
		opponent2 = self.matchData.opponents[2],
		---@param winningSide string
		---@param winBy string
		---@return Widget?
		iconRender = function(winningSide, winBy)
			local iconName = WIN_TYPE_TO_ICON[winBy]
			if not iconName then
				return
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
function MatchPage:_renderTeamStats(game)
	return {
		HtmlWidgets.H3{children = 'Team Stats'},
		Div{
			classes = {'match-bm-team-stats'},
			children = {
				Div{
					classes = {'match-bm-lol-team-stats-header'},
					children = {
						Div{
							classes = {'match-bm-lol-team-stats-header-team'},
							children = self.opponents[1].iconDisplay
						},
						Div{
							classes = {'match-bm-team-stats-list-cell'}
						},
						Div{
							classes = {'match-bm-lol-team-stats-header-team'},
							children = self.opponents[2].iconDisplay
						}
					}
				},
				StatsList{
					finished = game.finished,
					data = {
						{
							icon = nil,
							name = 'First Kills',
							team1Value = nil,
							team2Value = nil,
						},
						{
							icon = CREDS_ICON,
							name = 'Thrifties',
							team1Value = game.teams[1].thrifties,
							team2Value = game.teams[2].thrifties
						},
						{
							icon = CREDS_ICON,
							name = 'Post Plant',
							team1Value = nil,
							team2Value = nil
						},
						{
							icon = CREDS_ICON,
							name = 'Clutches',
							team1Value = game.teams[1].clutches,
							team2Value = game.teams[2].clutches
						},
					}
				}
			}
		}
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
			Array.map(
				Array.reverse(Array.sortBy(
					game.teams[teamIndex].players,
					function (player) return player.acs or 0 end
				)),
				function (player)
					return self:_renderPlayerPerformance(game, teamIndex, player)
				end
			)
		)
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@param player table
---@return Widget
function MatchPage:_renderPlayerPerformance(game, teamIndex, player)
	local formatNumbers = function(value, numberOfDecimals)
		if not value then
			return nil
		end
		numberOfDecimals = numberOfDecimals or 0
		local format = '%.'.. numberOfDecimals ..'f'
		return string.format(format, MathUtil.round(value, numberOfDecimals))
	end

	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-2'},
		children = {
			PlayerDisplay{
				characterIcon = self:getCharacterIcon(player.agent),
				characterName = player.agent,
				playerName = player.displayName or player.player,
				playerLink = player.player,
			},
			Div{
				classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-5'},
				children = {
					PlayerStat{
						title = {IconFa{iconName = 'acs'}, 'ACS'},
						data = player.acs and formatNumbers(player.acs) or nil,
					},
					PlayerStat{
						title = {IconFa{iconName = 'kda'}, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {IconFa{iconName = 'kast'}, 'KAST'},
						data = player.kast and (formatNumbers(player.kast, 1) .. '%') or nil
					},
					PlayerStat{
						title = {IconFa{iconName = 'damage'}, 'ADR'},
						data = player.adr and formatNumbers(player.adr) or nil
					},
					PlayerStat{
						title = {IconFa{iconName = 'headshot'}, 'HS%'},
						data = player.hs and (formatNumbers(player.hs, 1) .. '%') or nil
					}
				}
			}
		}
	}
end

return MatchPage
