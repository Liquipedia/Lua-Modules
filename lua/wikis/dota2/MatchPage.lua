---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table') ---@module 'commons.Table'
local TemplateEngine = require('Module:TemplateEngine')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local Display = Lua.import('Module:MatchPage/Template')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Link = Lua.import('Module:Widget/Basic/Link')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local VetoItem = Lua.import('Module:Widget/Match/Page/VetoItem')
local VetoRow = Lua.import('Module:Widget/Match/Page/VetoRow')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class Dota2MatchPage: BaseMatchPage
local MatchPage = Class.new(BaseMatchPage)

local NO_CHARACTER = 'default'
local KDA_ICON = '<i class="fas fa-skull-crossbones"></i>'
local GOLD_ICON = '<i class="fas fa-coins"></i>'
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

local AVAILABLE_FOR_TIERS = {1}
local MATCH_PAGE_START_TIME = 1725148800 -- September 1st 2024 midnight

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
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])
			team.players = Array.map(game.opponents[teamIdx].players or {}, function(player)
				local newPlayer = Table.mergeInto(player, {
					displayName = player.name or player.player,
					link = player.player,
					items = Array.map(player.items or {}, MatchPage.makeItemDisplay),
					backpackitems = Array.map(player.backpackitems or {}, MatchPage.makeItemDisplay),
					neutralitem = MatchPage.makeItemDisplay(player.neutralitem or {}),
				})

				newPlayer.displayDamageDone = MatchPage.abbreviateNumber(player.damagedone)
				newPlayer.displayGold = MatchPage.abbreviateNumber(player.gold)

				return newPlayer
			end)

			if game.finished then
				-- Aggregate stats
				team.gold = MatchPage.abbreviateNumber(MatchPage.sumItem(team.players, 'gold'))
				team.kills = MatchPage.sumItem(team.players, 'kills')
				team.deaths = MatchPage.sumItem(team.players, 'deaths')
				team.assists = MatchPage.sumItem(team.players, 'assists')

				-- Set fields
				team.objectives = game.extradata['team' .. teamIdx .. 'objectives']
			end

			team.picks = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'pick' and veto.team == teamIdx
			end)
			team.bans = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return team
		end)
	end)
end

function MatchPage:getCharacterIcon(character)
	local characterName = character
	if type(character) == 'table' then
		characterName = character.character
		---@cast character -table
	end
	return CharacterIcon.Icon{
		character = characterName or NO_CHARACTER,
		date = self.matchData.date
	}
end

function MatchPage.makeItemDisplay(item)
	if String.isEmpty(item.name) then
		return '[[File:EmptyIcon itemicon dota2 gameasset.png|64px|Empty|link=]]'
	end
	return '[[File:'.. item.image ..'|64px|'.. item.name ..'|link=]]'
end

---@param game MatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	local inputTable = Table.merge(self.matchData, game)
	inputTable.heroIcon = FnUtil.curry(self.getCharacterIcon, self)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderDraft(game),
			self:_renderTeamStats(game),
			TemplateEngine():render(Display.game, inputTable)
		)
	}
end

---@private
---@param game MatchPageGame
---@return Widget[]
function MatchPage:_renderDraft(game)
	return {
		HtmlWidgets.H3{children = 'Draft'},
		Div{
			classes = {'match-bm-game-veto-wrapper'},
			children = Array.map(self.opponents, function (opponent, opponentIndex)
				return self:_renderTeamVeto(game, opponent, opponentIndex)
			end)
		}
	}
end

---@private
---@param opponent MatchPageOpponent
---@param index integer
---@return Widget
function MatchPage:_renderTeamVeto(game, opponent, index)
	local team = game.teams[index]
	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-header'},
				children = opponent.iconDisplay
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto'},
				children = {
					VetoRow{
						vetoType = 'pick',
						side = team.side,
						vetoItems = Array.map(team.picks, function (pick)
							return VetoItem{
								characterIcon = self:getCharacterIcon(pick),
								vetoNumber = pick.vetoNumber
							}
						end)
					},
					VetoRow{
						vetoType = 'ban',
						vetoItems = Array.map(team.bans, function (ban)
							return VetoItem{
								characterIcon = self:getCharacterIcon(ban),
								vetoNumber = ban.vetoNumber
							}
						end)
					}
				}
			}
		}
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
					classes = {'match-bm-team-stats-header'},
					children = WidgetUtil.collect(
						HtmlWidgets.H4{
							classes = {'match-bm-team-stats-header-title'},
							children = game.finished
								and self.opponents[game.winner].name .. ' Victory'
								or 'No winner determined yet'
						},
						game.length and Div{children = game.length} or nil
					)
				},
				Div{
					classes = {'match-bm-team-stats-container'},
					children = {
						self:_renderStatsTeamDisplay(game, 1),
						StatsList{
							finished = game.finished,
							data = {
								{
									icon = KDA_ICON,
									name = 'KDA',
									team1Value = Array.interleave({
										game.teams[1].kills,
										game.teams[1].deaths,
										game.teams[1].assists
									}, SPAN_SLASH),
									team2Value = Array.interleave({
										game.teams[2].kills,
										game.teams[2].deaths,
										game.teams[2].assists
									}, SPAN_SLASH)
								},
								{
									icon = GOLD_ICON,
									name = 'Gold',
									team1Value = game.teams[1].gold,
									team2Value = game.teams[2].gold
								},
								{
									icon = '<i class="fas fa-chess-rook"></i>',
									name = 'Towers',
									team1Value = game.teams[1].objectives.towers,
									team2Value = game.teams[2].objectives.towers
								},
								{
									icon = '<i class="fas fa-warehouse"></i>',
									name = 'Barracks',
									team1Value = game.teams[1].objectives.barracks,
									team2Value = game.teams[2].objectives.barracks
								},
								{
									icon = HtmlWidgets.Span{
										classes = {'liquipedia-custom-icon', 'liquipedia-custom-icon-roshan'}
									},
									name = 'Roshans',
									team1Value = game.teams[1].objectives.roshans,
									team2Value = game.teams[2].objectives.roshans
								}
							}
						},
						self:_renderStatsTeamDisplay(game, 2)
					}
				}
			}
		}
	}
end

---@private
---@param game MatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderStatsTeamDisplay(game, teamIndex)
	local team = game.teams[teamIndex]
	return Div{
		classes = {'match-bm-team-stats-team'},
		children = {
			Div{
				classes = {'match-bm-team-stats-team-logo'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-team-stats-team-side'},
				children = team.side
			},
			Div{
				classes = {
					'match-bm-team-stats-team-state',
					'state--' .. team.scoreDisplay
				},
				children = team.scoreDisplay
			}
		}
	}
end

function MatchPage:getPatchLink()
	if Logic.isEmpty(self.matchData.patch) then return end
	return Link{ link = 'Version ' .. self.matchData.patch }
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
