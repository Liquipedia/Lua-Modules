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
local Table = Lua.import('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local PlayerStatContainer = Lua.import('Module:Widget/Match/Page/PlayerStat/Container')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local Span = Html.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CounterstrikeMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): CounterstrikeMatchPage
local MatchPage = Class.new(BaseMatchPage)

local SPAN_SLASH = Span{classes = {'slash'}, children = '/'}

-- Stat the player performance list is sorted by (descending). Potentially implement RWS / lp_rating
local SORT_STAT = 'adr'

-- How a round gets won, keyed by win types on Module:MatchGroup/Input/Custom/MatchPage
-- normalises end_reason, potentially should be an export (finn note)
local WIN_TYPES = {
	elimination = {icon = 'elimination', description = 'Enemy eliminated'},
	detonate = {icon = 'explosion_valorant', description = 'Bomb detonated'},
	defuse = {icon = 'defuse', description = 'Bomb defused'},
	time = {icon = 'outoftime', description = 'Time expired'},
	draw = {icon = 'draw', description = 'Round drawn'},
}
-- Fallback
local DEFAULT_WIN_ICON = 'elimination'

-- CS2 default competitive settings, MR24 reg block, 2x MR12 blocks, then OT blocks
local REGULATION_ROUNDS = 24
local ROUNDS_PER_HALF = 12
local OT_ROUNDS_PER_HALF = 6

---@param props {match: MatchGroupUtilMatch}
---@return VNode
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = game.opponents
		Array.forEach(game.teams, function(team, teamIdx)
			team.scoreDisplay = game.winner == teamIdx and 'win' or game.finished and 'loss' or '-'
		end)
	end)

	-- URL carry over
	self.matchData.links = Table.map(self.matchData.links, function(site, link)
		if type(link) == 'table' then
			return site, Array.map(link, function(entry)
				return type(entry) == 'table' and entry[1] or entry
			end)
		end
		return site, link
	end)
end

---@return Renderable?
function MatchPage:renderOverallStats()
	if self:isBestOfOne() then
		return
	end

	-- Only maps with player-level data contribute here -- see
	local overallPlayerData = {
		teams = Array.map(Array.range(1, 2), function(teamIdx)
			local team = {players = {}}
			local opponent = self.opponents[teamIdx]
			if opponent and opponent.players then
				team.players = Array.map(opponent.players, function(player)
					local playerData = player.extradata and player.extradata.overallStats
					if Logic.isEmpty(playerData) then
						return
					end
					---@cast playerData -nil
					playerData.player = playerData.player or player.pageName
					playerData.displayName = playerData.displayName or player.displayName
					return playerData
				end)
			end
			return team
		end)
	}

	return Html.Fragment{
		children = self:_renderPerformance(overallPlayerData)
	}
end

---@param game MatchPageGame
---@return VNode
function MatchPage:renderGame(game)
	return Html.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderRoundsOverview(game),
			self:_renderPerformance(game)
		)
	}
end

---game.extradata.t1sides/t1halfs (and t2) are parallel arrays for each team
---@param game MatchPageGame
---@param teamIndex 1|2
---@return {side: string, score: number}[]
local function getTeamHalvesDetails(game, teamIndex)
	local sides = game.extradata and game.extradata['t' .. teamIndex .. 'sides']
	local halfs = game.extradata and game.extradata['t' .. teamIndex .. 'halfs']
	if Logic.isEmpty(sides) or Logic.isEmpty(halfs) then
		return {}
	end
	---@cast sides -nil
	---@cast halfs -nil
	return Array.map(sides, function(side, index)
		return {side = side, score = halfs[index]}
	end)
end

---@private
---@param game MatchPageGame
---@return Widget
function MatchPage:_renderGameOverview(game)
	local team1 = getTeamHalvesDetails(game, 1)
	local team2 = getTeamHalvesDetails(game, 2)

	local function makeTeamHalvesDisplay(halves)
		return Div{
			classes = {'match-bm-game-summary-team-halves'},
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

	local scoreHolderContent = MatchGroupUtil.computeMatchPhase(game) ~= 'upcoming' and {
		Div{
			classes = {'match-bm-lol-game-summary-score'},
			children = {
				DisplayHelper.MapScore(game.opponents[1], game.status),
				'&#8209;', -- Non-breaking hyphen
				DisplayHelper.MapScore(game.opponents[2], game.status)
			}
		},
		Div{classes = {'match-bm-lol-game-summary-map'}, children = game.map},
		Div{classes = {'match-bm-lol-game-summary-length'}, children = game.length},
	} or nil

	return Div{
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
						children = scoreHolderContent
					},
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = WidgetUtil.collect(
							self.opponents[2].iconDisplay,
							makeTeamHalvesDisplay(team2)
						)
					},
				}
			}
		}
	}
end

---Renders nothing for maps without a round log (e.g. brack entered, non-nuselo data json maps maps).
---Split into blocks for stage of map
---@private
---@param game MatchPageGame
---@return Widget[]?
function MatchPage:_renderRoundsOverview(game)
	local rounds = game.extradata.rounds
	if Logic.isEmpty(rounds) then
		return nil
	end
	---@cast rounds -nil

	local regulationRounds = Array.sub(rounds, 1, math.min(REGULATION_ROUNDS, #rounds))
	local overtimeRounds = #rounds > REGULATION_ROUNDS and Array.sub(rounds, REGULATION_ROUNDS + 1, #rounds) or nil

	local function makeOverview(roundsSlice, roundsPerHalf)
		return RoundsOverview{
			rounds = roundsSlice,
			roundsPerHalf = roundsPerHalf,
			opponent1 = self.matchData.opponents[1],
			opponent2 = self.matchData.opponents[2],
			iconRender = MatchPage._renderRoundOutcomeIcon,
		}
	end

	return WidgetUtil.collect(
		makeOverview(regulationRounds, ROUNDS_PER_HALF),
		overtimeRounds and makeOverview(overtimeRounds, OT_ROUNDS_PER_HALF) or nil
	)
end

---Icon colouring to reflect side
---@private
---@param winningSide string
---@param winBy string?
---@return Widget
function MatchPage._renderRoundOutcomeIcon(winningSide, winBy)
	local winType = WIN_TYPES[winBy or ''] or {}
	return IconFa{
		iconName = winType.icon or DEFAULT_WIN_ICON,
		hover = winType.description,
		additionalClasses = {
			'match-bm-rounds-overview-round-outcome-icon',
			'match-bm-rounds-overview-round-outcome-icon--' .. winningSide,
			'brkts-cs-score-color-' .. winningSide,
		}
	}
end

---@private
---@param game MatchPageGame
---@return VNode[]
function MatchPage:_renderPerformance(game)
	return {
		Html.H3{children = 'Player Performance'},
		Div{
			classes = {'match-bm-players-wrapper'},
			children = {
				self:_renderTeamPerformance(game, 1),
				self:_renderTeamPerformance(game, 2),
			}
		}
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@return VNode
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
					game.teams[teamIndex].players or {},
					function(player) return player[SORT_STAT] or 0 end
				)),
				function(player)
					return MatchPage._renderPlayerPerformance(player)
				end
			)
		)
	}
end

---@private
---@param player CounterstrikeMatchPagePlayerStats
---@return VNode?
function MatchPage._renderPlayerPerformance(player)
	if Logic.isEmpty(player) then
		return
	end

	local formatNumbers = function(value, numberOfDecimals)
		if not value then
			return nil
		end
		return MathUtil.formatRounded{value = value, precision = numberOfDecimals}
	end

	-- Only link the name if the steamid resolved to a known Liquipedia player
	-- otherwise show the Mischief raw name as plain text. CRUCIAL, need to check playerId situation with _British player what not
	local nameDisplay = player.player
		and Link{link = player.player, children = player.displayName}
		or player.displayName

	local playerStats = {
		PlayerStat{
			title = {IconFa{iconName = 'kda'}, 'KDA'},
			data = Array.interleave({player.kills, player.deaths, player.assists}, SPAN_SLASH)
		},
		PlayerStat{
			title = {IconFa{iconName = 'damage'}, 'ADR'},
			data = player.adr and formatNumbers(player.adr, 1) or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'headshot'}, 'HS%'},
			data = player.hs and (formatNumbers(player.hs, 1) .. '%') or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'firstkill'}, 'FK / FD'},
			data = {player.firstKills, SPAN_SLASH, player.firstDeaths}
		},
		PlayerStat{
			title = {IconFa{iconName = 'kast'}, 'KAST'},
			data = player.kast and (formatNumbers(player.kast, 1) .. '%') or nil
		},
		PlayerStat{
			title = {IconFa{iconName = 'kills'}, 'AWP'},
			data = player.awpKills
		},
		PlayerStat{
			-- 'substitute' is people-arrows: the nearest thing the icon set has
			-- to an exchange, which is what a trade is.
			title = {IconFa{iconName = 'substitute'}, 'TK / TD'},
			data = {player.tradeKills, SPAN_SLASH, player.tradeDeaths}
		},
	}

	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-2'},
		children = {
			Div{
				classes = {'match-bm-players-player-name'},
				children = nameDisplay
			},
			PlayerStatContainer{
				columns = #playerStats,
				children = playerStats
			}
		}
	}
end

return MatchPage
