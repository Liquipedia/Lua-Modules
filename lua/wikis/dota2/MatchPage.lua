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

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
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
				})

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

---@param item {name: string?, image: string?}
---@return Widget
function MatchPage.makeItemDisplay(item)
	return IconImage{
		imageLight = Logic.emptyOr(item.image, 'EmptyIcon itemicon dota2 gameasset.png'),
		size = '64px',
		caption = Logic.emptyOr(item.name, 'Empty'),
		link = ''
	}
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
			self:_renderPlayersPerformance(game)
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

---@private
---@param game MatchPageGame
---@return Widget[]
function MatchPage:_renderPlayersPerformance(game)
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
				classes = {'match-bm-lol-players-team-header'},
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
			Div{
				classes = {'match-bm-players-player-character'},
				children = {
					Div{
						classes = {'match-bm-players-player-avatar'},
						children = {
							Div{
								classes = {'match-bm-players-player-icon'},
								children = self:getCharacterIcon(player)
							},
							Div{
								classes = {
									'match-bm-players-player-role',
									'role--' .. game.teams[teamIndex].side
								},
								children = IconImage{
									imageLight = 'Dota2 ' .. player.facet .. ' facet icon darkmode.png',
									caption = player.facet,
									link = ''
								}
							}
						}
					},
					Div{
						classes = {'match-bm-players-player-name'},
						children = {
							Link{link = player.link, children = player.displayName},
							HtmlWidgets.I{children = player.character}
						}
					}
				}
			},
			Div{
				classes = {'match-bm-players-player-loadout'},
				children = {
					Div{
						classes = {'match-bm-players-player-loadout-items'},
						children = WidgetUtil.collect(
							Array.map(player.items or {}, function (item)
								return Div{
									classes = {'match-bm-players-player-loadout-item'},
									children = MatchPage.makeItemDisplay(item)
								}
							end),
							Array.map(player.backpackitems or {}, function (backpackitem)
								return Div{
									classes = {'match-bm-players-player-loadout-item', 'item--backpack'},
									children = MatchPage.makeItemDisplay(backpackitem)
								}
							end)
						)
					},
					Div{
						classes = {'match-bm-players-player-loadout-rs-wrap'},
						children = Array.map({
							MatchPage.makeItemDisplay(player.neutralitem or {}),
							player.shard and IconImage{
								imageLight = 'Dota2_Aghanim\'s_Shard_symbol_allmode.png',
								size = '64px',
								caption = 'Aghanim\'s Shard',
								link = ''
							} or '',
							player.scepter and IconImage{
								imageLight = 'Dota2_Aghanim\'s_Scepter_symbol_allmode.png',
								size = '64px',
								caption = 'Aghanim\'s Scepter',
								link = ''
							} or ''
						}, function (specialItem)
							return Div{
								classes = {'match-bm-players-player-loadout-rs'},
								children = specialItem
							}
						end)
					}
				}
			},
			Div{
				classes = {'match-bm-players-player-stats'},
				children = {
					PlayerStat{
						title = {KDA_ICON, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {'<i class="fas fa-sword"></i>', 'DMG'},
						data = MatchPage.abbreviateNumber(player.damagedone)
					},
					PlayerStat{
						title = {'<i class="fas fa-swords"></i>', 'LH/DN'},
						data = {player.lasthits, SPAN_SLASH, player.denies}
					},
					PlayerStat{
						title = {'<i class="fas fa-coin"></i>', 'NET'},
						data = MatchPage.abbreviateNumber(player.gold)
					},
					PlayerStat{
						title = {GOLD_ICON, 'GPM'},
						data = player.gpm
					}
				}
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
