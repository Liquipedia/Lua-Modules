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

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local StatsResolver = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')

local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local PlayerStatContainer = Lua.import('Module:Widget/Match/Page/PlayerStat/Container')
local Span = Html.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CounterstrikeMatchPage: BaseMatchPage
---@operator call(MatchPageMatch): CounterstrikeMatchPage
local MatchPage = Class.new(BaseMatchPage)

local SPAN_SLASH = Span{classes = {'slash'}, children = '/'}

-- Stat the player performance list is sorted by (descending). Potentially implement RWS / lp_rating
local SORT_STAT = 'adr'

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
			team.players = StatsResolver.getPlayers(game.extradata.nuselo, teamIdx)
		end)
	end)
end

---@param game MatchPageGame
---@return VNode
function MatchPage:renderGame(game)
	return Html.Fragment{
		children = WidgetUtil.collect(
			self:_renderPerformance(game)
		)
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
