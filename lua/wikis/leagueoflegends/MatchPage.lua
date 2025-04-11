---
-- @Liquipedia
-- wiki=leagueoflegends
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
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TemplateEngine = require('Module:TemplateEngine')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local Display = Lua.import('Module:MatchPage/Template')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LoLMatchPageGame: MatchPageGame
---@field vetoGroups {type: 'ban'|'pick', team: integer, character: string, vetoNumber: integer}[][]

---@class LoLMatchPage: BaseMatchPage
---@field games LoLMatchPageGame[]
local MatchPage = Class.new(BaseMatchPage)

local KEYSTONES = Table.map({
	-- Precision
	'Press the Attack',
	'Lethal Tempo',
	'Fleet Footwork',
	'Conqueror',

	-- Domination
	'Electrocute',
	'Predator',
	'Dark Harvest',
	'Hail of Blades',

	-- Sorcery
	'Summon Aery',
	'Arcane Comet',
	'Phase Rush',

	-- Resolve
	'Grasp of the Undying',
	'Aftershock',
	'Guardian',

	-- Inspiration
	'Glacial Augment',
	'Unsealed Spellbook',
	'First Strike',
}, function(_, value)
	return value, true
end)

local NO_CHARACTER = 'default'

local DEFAULT_ITEM = 'EmptyIcon'
local AVAILABLE_FOR_TIERS = {1, 2, 3}
local ITEMS_TO_SHOW = 6

local MATCH_PAGE_START_TIME = 1619827201 -- May 1st 2021 midnight

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
		game.teams = Array.map(game.opponents, function(opponent, teamIdx)
			local team = {}

			team.scoreDisplay = game.winner == teamIdx and 'W' or game.finished and 'L' or '-'
			team.side = String.nilIfEmpty(game.extradata['team' .. teamIdx ..'side'])

			team.players = Array.map(opponent.players, function(player)
				if Logic.isDeepEmpty(player) then return end
				return Table.mergeInto(player, {
					roleIcon = player.role .. ' ' .. team.side,
					items = Array.map(Array.range(1, ITEMS_TO_SHOW), function(idx)
						return player.items[idx] or DEFAULT_ITEM
					end),
					runeKeystone = Array.filter(player.runes.primary.runes, function(rune)
						return KEYSTONES[rune]
					end)[1]
				})
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

			team.picks = Array.map(team.players, Operator.property('character'))
			team.bans = Array.filter(game.extradata.vetophase or {}, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return team
		end)

		local _, vetoByTeam = Array.groupBy(game.extradata.vetophase or {}, Operator.property('team'))
		game.vetoGroups = {}

		Array.forEach(vetoByTeam, function(team, teamIndex)
			local groupIndex = 1
			local lastType = 'ban'
			Array.forEach(team, function(veto)
				if lastType ~= veto.type then groupIndex = groupIndex + 1 end
				veto.groupIndex = groupIndex
				lastType = veto.type
			end)
			_, game.vetoGroups[teamIndex] = Array.groupBy(team, Operator.property('groupIndex'))
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

---@param game LoLMatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	local inputTable = Table.merge(self.matchData, game)
	inputTable.heroIcon = FnUtil.curry(self.getCharacterIcon, self)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderGamePicksAndBans(game),
			self:_renderTeamStats(game),
			TemplateEngine():render(Display.game, inputTable)
		)
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget?
function MatchPage:_renderGameOverview(game)
	if self:isBestOfOne() then return end
	return Div{
		classes = {'match-bm-lol-game-overview'},
		children = {
			Div{
				classes = {'match-bm-lol-game-summary'},
				children = {
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = self.opponents[1].iconDisplay
					},
					Div{
						classes = {'match-bm-lol-game-summary-center'},
						children = {
							Div{
								classes = {'match-bm-lol-game-summary-faction'},
								children = game.teams[1].side and IconImage{
									imageLight = 'Lol faction ' .. game.teams[1].side .. '.png',
									link = '',
									caption = game.teams[1].side .. ' side'
								} or nil
							},
							Div{
								classes = {'match-bm-lol-game-summary-score-holder'},
								children = game.finished and {
									Div{
										classes = {'match-bm-lol-game-summary-score'},
										children = {
											game.teams[1].scoreDisplay,
											'&ndash;',
											game.teams[2].scoreDisplay
										}
									},
									Div{
										classes = {'match-bm-lol-game-summary-length'},
										children = game.length
									}
								} or nil
							},
							Div{
								classes = {'match-bm-lol-game-summary-faction'},
								children = game.teams[2].side and IconImage{
									imageLight = 'Lol faction ' .. game.teams[2].side .. '.png',
									link = '',
									caption = game.teams[2].side .. ' side'
								} or nil
							}
						}
					},
					Div{
						classes = {'match-bm-lol-game-summary-team'},
						children = self.opponents[2].iconDisplay
					},
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]?
function MatchPage:_renderGamePicksAndBans(game)
	return {
		HtmlWidgets.H3{children = 'Picks and Bans'},
		Div{
			classes = {'match-bm-lol-game-veto', 'collapsed', 'general-collapsible'},
			children = {
				Div{
					classes = {'match-bm-lol-game-veto-overview'},
					children = Array.map({1, 2}, function (teamIndex)
						return self:_renderGameTeamVetoOverview(game, teamIndex)
					end)
				},
				Div{
					classes = {'match-bm-lol-game-veto-order-toggle', 'ppt-toggle-expand'},
					children = {
						Div{
							classes = {'general-collapsible-expand-button'},
							children = Div{children = {
								'Show Order &nbsp;',
								IconFa{iconName = 'expand'}
							}}
						},
						Div{
							classes = {'general-collapsible-collapse-button'},
							children = Div{children = {
								'Hide Order &nbsp;',
								IconFa{iconName = 'collapse'}
							}}
						}
					}
				},
				Div{
					classes = {'match-bm-lol-game-veto-order-list', 'ppt-hide-on-collapse'},
					children = {
						self:_renderGameTeamVetoOrder(game, 1),
						self:_renderGameTeamVetoOrder(game, 2),
					}
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderGameTeamVetoOverview(game, teamIndex)
	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-lol-game-veto-overview-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-overview-team-veto'},
				children = {
					HtmlWidgets.Ul{
						classes = {'match-bm-lol-game-veto-overview-pick'},
						attributes = {['aria-labelledby'] = 'picks'},
						children = Array.map(game.teams[teamIndex].picks, function (pick)
							return HtmlWidgets.Li{
								classes = {'match-bm-lol-game-veto-overview-item'},
								children = {
									self:getCharacterIcon(pick),
									Div{classes = {'match-bm-lol-game-veto-pick-bar-' .. game.teams[teamIndex].side}}
								}
							}
						end)
					},
					HtmlWidgets.Ul{
						classes = {'match-bm-lol-game-veto-overview-ban'},
						attributes = {['aria-labelledby'] = 'bans'},
						children = Array.map(game.teams[teamIndex].bans, function (ban)
							return HtmlWidgets.Li{
								classes = {'match-bm-lol-game-veto-overview-item'},
								children = {self:getCharacterIcon(ban)}
							}
						end)
					}
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
---@param teamIndex integer
---@return Widget
function MatchPage:_renderGameTeamVetoOrder(game, teamIndex)
	return Div{
		classes = {'match-bm-lol-game-veto-order-team'},
		children = {
			Div{
				classes = {'match-bm-lol-game-veto-order-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-order-team-choices'},
				children = Array.map(game.vetoGroups[teamIndex], function (vetoGroup)
					return Div{
						classes = {'match-bm-lol-game-veto-order-team-choice-group'},
						children = Array.map(vetoGroup, function (veto)
							return Div{
								classes = Array.extend(
									'match-bm-lol-game-veto-order-team-choice',
									veto.type == 'ban' and 'match-bm-lol-game-veto-order-ban' or nil
								),
								attributes = {['aria-labelledby'] = 'round ' .. veto.vetoNumber .. ' ' .. veto.type},
								children = {
									Div{
										classes = Array.extend(
											'match-bm-lol-game-veto-order-step',
											veto.type == 'pick' and (
												'match-bm-lol-game-veto-order-step-' .. game.teams[teamIndex].side
											) or nil
										),
										children = {veto.vetoNumber}
									},
									self:getCharacterIcon(veto)
								}
							}
						end)
					}
				end)
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
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
						Div{classes = {'match-bm-team-stats-list-cell'}},
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
							icon = IconImage{imageLight = 'Lol stat icon kda.png', link = ''},
							name = 'KDA',
							team1Value = Array.interleave({
								game.teams[1].kills,
								game.teams[1].deaths,
								game.teams[1].assists
							}, HtmlWidgets.Span{classes = {'slash'}, children = '/'}),
							team2Value = Array.interleave({
								game.teams[2].kills,
								game.teams[2].deaths,
								game.teams[2].assists
							}, HtmlWidgets.Span{classes = {'slash'}, children = '/'})
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon gold.png', link = ''},
							name = 'Gold',
							team1Value = game.teams[1].gold,
							team2Value = game.teams[2].gold
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon tower.png', link = ''},
							name = 'Towers',
							team1Value = game.teams[1].objectives.towers,
							team2Value = game.teams[2].objectives.towers
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon inhibitor.png', link = ''},
							name = 'Inhibitors',
							team1Value = game.teams[1].objectives.inhibitors,
							team2Value = game.teams[2].objectives.inhibitors
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon baron.png', link = ''},
							name = 'Barons',
							team1Value = game.teams[1].objectives.barons,
							team2Value = game.teams[2].objectives.barons
						},
						{
							icon = IconImage{imageLight = 'Lol stat icon dragon.png', link = ''},
							name = 'Dragons',
							team1Value = game.teams[1].objectives.dragons,
							team2Value = game.teams[2].objectives.dragons
						}
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
