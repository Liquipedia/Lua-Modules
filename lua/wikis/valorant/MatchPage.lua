---
-- @Liquipedia
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Carousel = Lua.import('Module:Widget/Basic/Carousel')
local Div = HtmlWidgets.Div
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local PlayerStatContainer = Lua.import('Module:Widget/Match/Page/PlayerStat/Container')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local Span = HtmlWidgets.Span
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local WidgetUtil = Lua.import('Module:Widget/Util')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@class ValorantMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): ValorantMatchPage
local MatchPage = Class.new(BaseMatchPage)

local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

local ROUNDS_BEFORE_SPLIT = 12
local WIN_TYPES = {
	['elimination'] = {
		icon = 'elimination',
		description = 'Enemy eliminated',
	},
	['detonate'] = {
		icon = 'explosion_valorant',
		description = 'Spike detonated',
	},
	['defuse'] = {
		icon = 'defuse',
		description = 'Spike defused',
	},
	['time'] = {
		icon = 'outoftime',
		description = 'Timer expired',
	}
}

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = game.opponents
		Array.forEach(game.teams, function(team, teamIdx)
			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.postPlant = team.postPlant or {}
		end)
	end)
end

---@return Widget?
function MatchPage:renderOverallStats()
	if self:isBestOfOne() then
		return
	end

	local overallTeamData = {
		finished = true,
		teams = Array.map(self.opponents, Operator.property('extradata'))
	}

	local overallPlayerData = {
		teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = { players = {} }
			local opponent = self.opponents[teamIdx]
			if opponent and opponent.players then
				team.players = Array.map(opponent.players, function(player)
					if not player.extradata or not player.extradata.overallStats then
						return
					end
					local playerData = player.extradata.overallStats

					if not playerData.roundsPlayed or playerData.roundsPlayed == 0 then
						return
					end

					playerData.player = player.pageName
					playerData.displayName = player.displayName
					return playerData
				end)
			end
			return team
		end)
	}

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderTeamStats(overallTeamData),
			self:_renderPerformance(overallPlayerData)
		)
	}
end

---@param game MatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderRoundsOverview(game),
			self:_renderRoundDetails(game),
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
			local iconName = (WIN_TYPES[winBy] or {}).icon
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
							classes = {'match-bm-team-stats-list-cell'},
							children = self:getTournamentIcon()
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
							icon = IconFa{iconName = 'team_firstkills'},
							name = 'First Kills',
							team1Value = game.teams[1].firstKills,
							team2Value = game.teams[2].firstKills,
						},
						{
							icon = IconImage{
								imageLight = 'Black Creds VALORANT.png',
								imageDark = 'White Creds VALORANT.png',
								size = '16px',
							},
							name = 'Thrifties',
							team1Value = game.teams[1].thrifties,
							team2Value = game.teams[2].thrifties
						},
						{
							icon = IconImage{
								imageLight = 'VALORANT Spike lightmode.png',
								imageDark = 'VALORANT Spike darkmode.png',
								size = '16px',
							},
							name = 'Post Plant',
							team1Value = Array.interleave(game.teams[1].postPlant, SPAN_SLASH),
							team2Value = Array.interleave(game.teams[2].postPlant, SPAN_SLASH)
						},
						{
							icon = IconImage{
								imageLight = 'VALORANT clutch lightmode.png',
								imageDark = 'VALORANT clutch darkmode.png',
								size = '16px',
							},
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

---@param game MatchPageGame
---@param puuid string
---@return {player: string, displayName: string}?
function MatchPage._findPlayerByPuuid(game, puuid)
	for _, opponent in ipairs(game.opponents) do
		for _, player in ipairs(opponent.players) do
			if player.puuid == puuid then
				return player
			end
		end
	end
end

---@private
---@param game MatchPageGame
---@return Widget
function MatchPage:_renderRoundDetails(game)
	local findPlayer = FnUtil.memoize(FnUtil.curry(MatchPage._findPlayerByPuuid, game))

	---@param ceremony string
	---@return Widget?
	local function displayCeremony(ceremony)
		if Logic.isEmpty(ceremony) then
			return
		end
		if ceremony == 'Clutch' then
			return Span{children = {
				IconImage{
					imageLight = 'VALORANT clutch lightmode.png',
					imageDark = 'VALORANT clutch darkmode.png',
					size = '16px',
				},
				' ',
				HtmlWidgets.B{children = 'CLUTCH'}
			}}
		end
		if ceremony == 'Ace' then
			return Span{children = {
				'<i class="far fa-thumbs-up"></i>',
				' ',
				HtmlWidgets.B{children = 'ACE'}
			}}
		end
		if ceremony == 'Thrifty' then
			return Span{children = {
				IconImage{
					imageLight = 'Black Creds VALORANT.png',
					imageDark = 'White Creds VALORANT.png',
					size = '16px',
				},
				' ',
				HtmlWidgets.B{children = 'THRIFTY'}
			}}
		end
	end

	return GeneralCollapsible{
		title = 'Round Details',
		classes = {'match-bm-match-collapsible'},
		shouldCollapse = true,
		children = Carousel{
			classes = {'match-bm-match-collapsible-content'},
			children = Array.map(game.extradata.rounds --[[ @as ValorantRoundData[] ]], function (round, roundIndex)
				local firstKillPlayer = findPlayer(round.firstKill.killer) or {}
				local roundWinType = WIN_TYPES[round.winBy] or {}
				return Div{
					classes = {'match-bm-match-round-detail'},
					children = WidgetUtil.collect(
						HtmlWidgets.B{
							classes = {'match-bm-rounds-overview-round-outcome-icon--' .. round.winningSide},
							css = {
								padding = '0.25rem',
								['border-radius'] = '0.25rem',
							},
							children = {
								'Round ',
								roundIndex,
							}
						},
						Span{children = {
							IconFa{
								iconName = roundWinType.icon,
								hover = String.upperCaseFirst(round.winBy),
							},
							' ',
							HtmlWidgets.B{children = roundWinType.description}
						}},
						Span{children = {
							IconFa{iconName = 'team_firstkills'},
							HtmlWidgets.B{children = ' First Kill:'},
							' ',
							Link{link = firstKillPlayer.player, children = firstKillPlayer.displayName}
						}},
						Span{children = {
							'<i class="fas fa-fist-raised"></i> ',
							HtmlWidgets.B{children = 'Winner:'},
							' ',
							self.opponents[(round.winningSide == round.t1side) and 1 or 2].iconDisplay
						}},
						displayCeremony(round.ceremony)
					)
				}
			end)
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
				self:_renderTeamPerformance(game, 1),
				self:_renderTeamPerformance(game, 2)
			}
		}
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderTeamPerformance(game, teamIndex)
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
					return self:_renderPlayerPerformance(player)
				end
			)
		)
	}
end

---@private
---@param player table
---@return Widget?
function MatchPage:_renderPlayerPerformance(player)
	if Logic.isEmpty(player) then
		return
	end

	local formatNumbers = function(value, numberOfDecimals)
		if not value then
			return nil
		end
		return MathUtil.formatRounded{value = value, precision = numberOfDecimals}
	end

	local playerDisplay
	if type(player.agent) == 'table' then
		playerDisplay = Div{
			classes = {'match-bm-players-player-name'},
			children = {
				Link{link = player.player, children = player.displayName},
				MatchSummaryWidgets.Characters{characters = player.agent, date = self.matchData.date},
			}
		}
	else
		playerDisplay = PlayerDisplay{
			characterIcon = self:getCharacterIcon(player.agent),
			characterName = player.agent,
			playerName = player.displayName or player.player,
			playerLink = player.player,
		}
	end

	local playerStats = {
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
	}

	if player.hs then
		table.insert(playerStats, PlayerStat{
			title = {IconFa{iconName = 'headshot'}, 'HS%'},
			data = (formatNumbers(player.hs, 1) .. '%')
		})
	end

	table.insert(playerStats, PlayerStat{
		title = {IconFa{iconName = 'firstkill'}, 'FK / FD'},
		data = {player.firstKills, SPAN_SLASH, player.firstDeaths}
	})

	local numCols = #playerStats

	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-2'},
		children = {
			playerDisplay,
			PlayerStatContainer{
				columns = numCols,
				children = playerStats
			}
		}
	}
end

return MatchPage
