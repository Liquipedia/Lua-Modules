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
local Table = require('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Link = Lua.import('Module:Widget/Basic/Link')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
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
			self:_renderPerformance(game)
		)
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
		classes = {'match-bm-players-player'},
		children = {
			PlayerDisplay{
				characterIcon = self:getCharacterIcon(player.character),
				characterName = player.character,
				playerName = player.displayName,
				playerLink = player.link
			},
			Div{
				classes = {'match-bm-players-player-stats'},
				children = {
					PlayerStat{
						title = {IconFa{iconName = 'XXX'}, 'ACS'},
						data = player.asc
					},
					PlayerStat{
						title = {IconFa{iconName = 'dota2_kda'}, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {IconFa{iconName = 'XXX'}, 'KAST'},
						data = player.kast and (player.kast .. '%') or nil
					},
					PlayerStat{
						title = {IconFa{iconName = 'damage'}, 'ADR'},
						data = player.asc
					},
					PlayerStat{
						title = {IconFa{iconName = 'XXX'}, 'HS%'},
						data = player.hs and (player.hs .. '%') or nil
					}
				}
			}
		}
	}
end

function MatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Patch ' .. self.matchData.patch }
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
