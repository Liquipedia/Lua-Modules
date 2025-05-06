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
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Table = require('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local RoundsOverview = Lua.import('Module:Widget/Match/Page/RoundsOverview')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ValorantMatchPage: BaseMatchPage
local MatchPage = Class.new(BaseMatchPage)

local AVAILABLE_FOR_TIERS = {1}
local MATCH_PAGE_START_TIME = 1746050400 -- May 1st 2025 midnight
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

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
			team.players = Array.map(game.opponents[teamIdx].players or {}, function(player)
				local newPlayer = Table.mergeInto(player, {
					displayName = player.name or player.player,
					link = player.player,
				})

				return newPlayer
			end)

			return team
		end)
	end)
end

---@param game MatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderRoundsOverview(game),
			self:_renderPerformance(game)
		)
	}
end

---@private
---@param game MatchPageGame
---@return Widget
function MatchPage:_renderRoundsOverview(game)
	return RoundsOverview{
		rounds = game.extradata.rounds,
		iconRender = function(winningSide, winBy)
			local iconName
			if winBy == 'elimination' then
				iconName = 'skull'
			elseif winBy == 'explosion' then
				iconName = 'fire-alt'
			elseif winBy == 'defuse' then
				iconName = 'wrench'
			else
				iconName = 'hourglass-end'
			end
			return Div{
				classes = {'match-bm-rounds-overview-round-outcome-icon'},
				css = {
					['background-color'] = winningSide == 'atk' and '#B20110' or '#01654C',
					color = 'white',
					['border-radius'] = '0.25rem',
					height = '1.75rem',
					width = '1.75rem',
					['text-align'] = 'center',
					['font-size'] = '1.25rem',
					display = 'flex',
					['align-items'] = 'center',
					['justify-content'] = 'center',
				},
				children = '<i class="fas fa-' .. iconName .. '"></i>'
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
				playerName = player.displayName,
				playerLink = player.link
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

---@return MatchPageComment[]
function MatchPage:addComments()
	local casters = Json.parseIfString(self.matchData.extradata.casters)
	if Logic.isEmpty(casters) then return {} end
	return {
		Comment{
			children = WidgetUtil.collect(
				#casters > 1 and 'Casters: ' or 'Caster: ',
				Array.interleave(DisplayHelper.createCastersDisplay(casters), ', ')
			)
		}
	}
end

return MatchPage
