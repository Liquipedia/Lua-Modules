---
-- @Liquipedia
-- wiki=dota2
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
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Link = Lua.import('Module:Widget/Basic/Link')
local Comment = Lua.import('Module:Widget/Match/Page/Comment')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local TeamVeto = Lua.import('Module:Widget/Match/Page/TeamVeto')
local VetoItem = Lua.import('Module:Widget/Match/Page/VetoItem')
local VetoRow = Lua.import('Module:Widget/Match/Page/VetoRow')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class Dota2MatchPage: BaseMatchPage
local MatchPage = Class.new(BaseMatchPage)

local GOLD_ICON = IconFa{iconName = 'gold', hover = 'Gold'}
local ITEM_IMAGE_SIZE = '64px'
local KDA_ICON = IconFa{iconName = 'dota2_kda', hover = 'KDA'}
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
			else
				team.objectives = {}
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

---@param item {name: string?, image: string?}
---@return Widget
function MatchPage.makeItemDisplay(item)
	return IconImage{
		imageLight = Logic.emptyOr(item.image, 'EmptyIcon itemicon dota2 gameasset.png'),
		size = ITEM_IMAGE_SIZE,
		caption = Logic.emptyOr(item.name, 'Empty'),
		link = ''
	}
end

---@param game MatchPageGame
---@return Widget
function MatchPage:renderGame(game)
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
				return TeamVeto{
					teamIcon = opponent.iconDisplay,
					vetoRows = self:_generateVetoRows(game, opponentIndex)
				}
			end)
		}
	}
end

---@private
---@param game MatchPageGame
---@param opponentIndex integer
---@return MatchPageVetoRow[]
function MatchPage:_generateVetoRows(game, opponentIndex)
	local team = game.teams[opponentIndex]
	local picks = team.picks or {}
	local bans = team.bans or {}
	if Logic.isNotEmpty(picks) and Logic.isNotEmpty(bans) then
		-- Load data from Dota2DB
		return {
			VetoRow{
				vetoType = 'pick',
				side = team.side,
				vetoItems = Array.map(picks, function (pick)
					return VetoItem{
						characterIcon = self:getCharacterIcon(pick.character),
						vetoNumber = pick.vetoNumber
					}
				end)
			},
			VetoRow{
				vetoType = 'ban',
				vetoItems = Array.map(bans, function (ban)
					return VetoItem{
						characterIcon = self:getCharacterIcon(ban.character),
						vetoNumber = ban.vetoNumber
					}
				end)
			}
		}
	end

	-- Load data from manual input
	local extradata = game.extradata or {}

	for _, pick in Table.iter.pairsByPrefix(extradata, 'team' .. opponentIndex .. 'hero') do
		table.insert(picks, pick)
	end

	for _, ban in Table.iter.pairsByPrefix(extradata, 'team' .. opponentIndex .. 'ban') do
		table.insert(bans, ban)
	end

	return {
		VetoRow{
			vetoType = 'pick',
			side = extradata['team' .. opponentIndex .. 'side'],
			vetoItems = Array.map(picks, function (pick)
				return VetoItem{
					characterIcon = self:getCharacterIcon(pick),
					vetoNumber = pick.vetoNumber
				}
			end)
		},
		VetoRow{
			vetoType = 'ban',
			vetoItems = Array.map(bans, function (ban)
				return VetoItem{
					characterIcon = self:getCharacterIcon(ban),
					vetoNumber = ban.vetoNumber
				}
			end)
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
									icon = IconFa{iconName = 'dota2_tower'},
									name = 'Towers',
									team1Value = game.teams[1].objectives.towers,
									team2Value = game.teams[2].objectives.towers
								},
								{
									icon = IconFa{iconName = 'dota2_barrack'},
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
				side = game.teams[teamIndex].side,
				roleIcon = player.facet and IconImage{
					imageLight = 'Dota2 ' .. player.facet .. ' facet icon darkmode.png',
					caption = player.facet,
					link = ''
				} or nil,
				playerName = player.displayName,
				playerLink = player.link
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
								size = ITEM_IMAGE_SIZE,
								caption = 'Aghanim\'s Shard',
								link = ''
							} or '',
							player.scepter and IconImage{
								imageLight = 'Dota2_Aghanim\'s_Scepter_symbol_allmode.png',
								size = ITEM_IMAGE_SIZE,
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
						title = {IconFa{iconName = 'damage'}, 'DMG'},
						data = MatchPage.abbreviateNumber(player.damagedone)
					},
					PlayerStat{
						title = {IconFa{iconName = 'dota2_lhdn'}, 'LH/DN'},
						data = Array.interleave({player.lasthits, player.denies}, SPAN_SLASH)
					},
					PlayerStat{
						title = {GOLD_ICON, 'NET'},
						data = MatchPage.abbreviateNumber(player.gold)
					},
					PlayerStat{
						title = {IconFa{iconName = 'dota2_gpm'}, 'GPM'},
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
