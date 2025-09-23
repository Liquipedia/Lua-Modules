---
-- @Liquipedia
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local WidgetUtil = Lua.import('Module:Widget/Util')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@class ValorantMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): ValorantMatchPage
local MatchPage = Class.new(BaseMatchPage)

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
			local rounds = game.extradata.rounds or {} --[[ @as ValorantRoundData[] ]]
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'winner' or game.finished and 'loser' or '-'
			team.players = Array.filter(game.opponents[teamIdx].players or {}, Table.isNotEmpty)

			team.thrifties = #Array.filter(rounds, function (round)
				return round['t' .. teamIdx .. 'side'] == round.winningSide and round.ceremony == 'Thrifty'
			end)

			team.firstKills = #Array.filter(rounds, function (round)
				return round.firstKill.byTeam == teamIdx
			end)

			Array.forEach(team.players, function (player)
				player.firstKills = #Array.filter(rounds, function (round)
					return round.firstKill.killer == player.puuid
				end)
				player.firstDeaths = #Array.filter(rounds, function (round)
					return round.firstKill.victim == player.puuid
				end)
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

---@private
---@return Widget
function MatchPage:_renderGamesOverview()
	local allPlayersStats = {}

	Array.forEach(self.games, function(game)
		if game.status ~= BaseMatchPage.NOT_PLAYED then
			Array.forEach(Array.range(1, 2), function(teamIdx)
				Array.forEach(game.opponents[teamIdx].players or {}, function(player)
					local playerId = player.player
					if not playerId then return end

					if not allPlayersStats[playerId] then
						allPlayersStats[playerId] = {
							displayName = player.displayName or player.player,
							playerLink = player.player,
							teamIndex = teamIdx,
							agents = {},
							stats = {
								acs = {},
								kast = {},
								adr = {},
								hs = {},
								kills = 0,
								deaths = 0,
								assists = 0,
							}
						}
					end

					local data = allPlayersStats[playerId]
					if player.agent then
						table.insert(data.agents, player.agent)
					end

					local stats = data.stats
					if player.acs then table.insert(stats.acs, player.acs) end
					if player.kast then table.insert(stats.kast, player.kast) end
					if player.adr then table.insert(stats.adr, player.adr) end
					if player.hs then table.insert(stats.hs, player.hs) end
					stats.kills = stats.kills + (player.kills or 0)
					stats.deaths = stats.deaths + (player.deaths or 0)
					stats.assists = stats.assists + (player.assists or 0)
				end)
			end)
		end
	end)

	local function average(statTable)
		if #statTable == 0 then return nil end
		local sum = Array.reduce(statTable, Operator.add)
		return sum / #statTable
	end

	local team1Players = {}
	local team2Players = {}

	for _, playerData in pairs(allPlayersStats) do
		local stats = playerData.stats
		playerData.avgAcs = average(stats.acs)
		playerData.avgKast = average(stats.kast)
		playerData.avgAdr = average(stats.adr)
		playerData.avgHs = average(stats.hs)

		if playerData.teamIndex == 1 then
			table.insert(team1Players, playerData)
		else
			table.insert(team2Players, playerData)
		end
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			HtmlWidgets.H3{children = 'Overall Player Performance'},
			Div{
				classes = {'match-bm-players-wrapper'},
				children = {
					self:_renderTeamPerformance(1, team1Players, 'avgAcs', true),
					self:_renderTeamPerformance(2, team2Players, 'avgAcs', true)
				}
			}
		)
	}
end

---@return string|Html|Widget?
function MatchPage:renderGames()
	local games = Array.map(Array.filter(self.games, function(game)
		return game.status ~= BaseMatchPage.NOT_PLAYED
	end), function(game)
		return self:renderGame(game)
	end)

	if #games < 2 then
		return games[1]
	end

	---@type table<string, any>
	local tabs = {
		This = 1,
		['hide-showall'] = true,
		name1 = 'All games',
		content1 = self:_renderGamesOverview(),
	}

	Array.forEach(games, function(game, idx)
		local tabIndex = idx + 1
		local mapName = self.games[idx].map
		if Logic.isNotEmpty(mapName) then
			tabs['name' .. tabIndex] = 'Game ' .. idx .. ': ' .. mapName
		else
			tabs['name' .. tabIndex] = 'Game ' .. idx
		end
		tabs['content' .. tabIndex] = game
	end)

	return Tabs.dynamic(tabs)
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
							classes = {'match-bm-team-stats-list-cell'},
							children = IconImage{
								imageLight = self:getMatchContext().icon,
								imageDark = self:getMatchContext().icondark,
								size = 'x25px',
							}
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

---@private
---@param game MatchPageGame
---@return Widget[]
function MatchPage:_renderPerformance(game)
	return {
		HtmlWidgets.H3{children = 'Player Performance'},
		Div{
			classes = {'match-bm-players-wrapper'},
			children = {
				self:_renderTeamPerformance(1, game.teams[1].players, 'acs', false),
				self:_renderTeamPerformance(2, game.teams[2].players, 'acs', false)
			}
		}
	}
end

---@private
---@param teamIndex integer
---@param players table[]
---@param sortKey string
---@param isOverall boolean
---@return Widget
function MatchPage:_renderTeamPerformance(teamIndex, players, sortKey, isOverall)
	return Div{
		classes = {'match-bm-players-team'},
		children = WidgetUtil.collect(
			Div{
				classes = {'match-bm-players-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Array.map(
				Array.reverse(Array.sortBy(
					players,
					function (player) return player[sortKey] or 0 end
				)),
				function (player)
					return self:_renderPlayerPerformance(player, isOverall)
				end
			)
		)
	}
end

---@private
---@param value number?
---@param numberOfDecimals number?
---@return string|nil
local function formatNumbers(value, numberOfDecimals)
	if not value then
		return nil
	end
	numberOfDecimals = numberOfDecimals or 0
	local format = '%.'.. numberOfDecimals ..'f'
	return string.format(format, MathUtil.round(value, numberOfDecimals))
end

---@private
---@param player table
---@param isOverall boolean
---@return Widget
function MatchPage:_renderPlayerPerformance(player, isOverall)
	local playerDisplay, statsData, numCols

	if isOverall then
		statsData = {
			acs = player.avgAcs,
			kills = player.stats.kills,
			deaths = player.stats.deaths,
			assists = player.stats.assists,
			kast = player.avgKast,
			adr = player.avgAdr,
			hs = player.avgHs,
		}
		numCols = 5
		playerDisplay = Div{
			classes = {'match-bm-players-player-name'},
			children = {
				Link{link = player.playerLink, children = player.displayName},
				MatchSummaryWidgets.Characters{characters = player.agents},
			}
		}
	else
		statsData = player
		numCols = 6
		playerDisplay = PlayerDisplay{
			characterIcon = self:getCharacterIcon(player.agent),
			characterName = player.agent,
			playerName = player.displayName or player.player,
			playerLink = player.player,
		}
	end

	local statWidgets = {
		PlayerStat{
			title = {IconFa{iconName = 'acs'}, 'ACS'},
			data = statsData.acs and formatNumbers(statsData.acs) or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'kda'}, 'KDA'},
			data = Array.interleave({ statsData.kills, statsData.deaths, statsData.assists }, SPAN_SLASH)
		},
		PlayerStat{
			title = {IconFa{iconName = 'kast'}, 'KAST'},
			data = statsData.kast and (formatNumbers(statsData.kast, 1) .. '%') or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'damage'}, 'ADR'},
			data = statsData.adr and formatNumbers(statsData.adr) or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'headshot'}, 'HS%'},
			data = statsData.hs and (formatNumbers(statsData.hs, 1) .. '%') or nil
		},
	}

	if not isOverall then
		table.insert(statWidgets, PlayerStat{
			title = {IconFa{iconName = 'firstkill'}, 'FK / FD'},
			data = {statsData.firstKills, SPAN_SLASH, statsData.firstDeaths}
		})
	end

	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-2'},
		children = {
			playerDisplay,
			Div{
				classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-' .. numCols},
				children = statWidgets
			}
		}
	}
end

return MatchPage
