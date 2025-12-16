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
local InGameRoles = Lua.import('Module:InGameRoles', {loadData = true})
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local BaseMatchPage = Lua.import('Module:MatchPage/Base')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local GeneralCollapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local MatchSummaryCharacters = Lua.import('Module:Widget/Match/Summary/Characters')
local PlayerStat = Lua.import('Module:Widget/Match/Page/PlayerStat')
local PlayerDisplay = Lua.import('Module:Widget/Match/Page/PlayerDisplay')
local StatsList = Lua.import('Module:Widget/Match/Page/StatsList')
local VetoItem = Lua.import('Module:Widget/Match/Page/VetoItem')
local VetoRow = Lua.import('Module:Widget/Match/Page/VetoRow')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class LoLMatchPageGame: MatchPageGame
---@field vetoGroups {type: 'ban'|'pick', team: integer, character: string, vetoNumber: integer}[][][]
---@field opponents {players: table[], score: number?, status: string?, [string]: any}[]

---@class LoLMatchPage: BaseMatchPage
---@field games LoLMatchPageGame[]
---@operator call(MatchGroupUtilMatch): BaseMatchPage
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

local DEFAULT_ITEM = 'EmptyIcon'
local LOADOUT_ICON_SIZE = '64px'
local ITEMS_TO_SHOW = 6

local KDA_ICON = IconFa{iconName = 'leagueoflegends_kda', hover = 'KDA'}
local GOLD_ICON = IconFa{iconName = 'gold', hover = 'Gold'}
local SPAN_SLASH = HtmlWidgets.Span{classes = {'slash'}, children = '/'}

---@param props {match: MatchGroupUtilMatch}
---@return Widget
function MatchPage.getByMatchId(props)
	local matchPage = MatchPage(props.match)

	return matchPage:render()
end

function MatchPage:populateGames()
	Array.forEach(self.games, function(game)
		local vetoPhase = game.extradata.vetophase or {}
		game.finished = game.winner ~= nil and game.winner ~= -1
		game.teams = Array.map(game.opponents, function(opponent, teamIdx)
			opponent.scoreDisplay = game.winner == teamIdx and 'W' or game.finished and 'L' or '-'

			opponent.players = Array.map(
				Array.sortBy(Array.filter(opponent.players, Logic.isNotEmpty), function(player)
					return InGameRoles[player.role].sortOrder
				end),
				function(player)
					if Logic.isDeepEmpty(player) then return end
					return Table.mergeInto(player, {
						items = Array.map(Array.range(1, ITEMS_TO_SHOW), function(idx)
							return player.items[idx] or DEFAULT_ITEM
						end),
						runeKeystone = Array.filter(player.runes.primary.runes or {}, function(rune)
							return KEYSTONES[rune]
						end)[1]
					})
				end
			)
			opponent.pickOrder = Array.filter(vetoPhase, function(veto)
				return veto.type == 'pick' and veto.team == teamIdx
			end)
			opponent.bans = Array.filter(vetoPhase, function(veto)
				return veto.type == 'ban' and veto.team == teamIdx
			end)

			return opponent
		end)

		local _, vetoByTeam = Array.groupBy(vetoPhase, Operator.property('team'))
		game.vetoGroups = Array.map(vetoByTeam, function (team)
			return Array.groupAdjacentBy(team, Operator.property('type'))
		end)
	end)
end

---@return Widget?
function MatchPage:renderOverallStats()
	if self:isBestOfOne() then
		return
	end

	local function renderOverallTeamStats()
		return {
			HtmlWidgets.H3{children = 'Overall Team Stats'},
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
					MatchPage._buildTeamStatsList{
						finished = true,
						data = Array.map(self.matchData.opponents, Operator.property('extradata'))
					}
				}
			}
		}
	end

	---@param stat integer
	---@param gameLength integer
	---@return string?
	local function calculateStatPerMinute(stat, gameLength)
		if gameLength <= 0 then
			return
		end
		return MathUtil.formatRounded{precision = 2, value = stat / gameLength * 60}
	end

	---@param player standardPlayer
	---@return Widget?
	local function renderPlayerOverallPerformance(player)
		if Logic.isEmpty(player.extradata) then
			return
		end
		return Div{
			classes = {'match-bm-players-player match-bm-players-player--col-2'},
			children = WidgetUtil.collect(
				Div{
					classes = {'match-bm-players-player-name match-bm-players-player-name-overall'},
					children = {
						Link{link = player.pageName, children = player.displayName},
						MatchSummaryCharacters{characters = player.extradata.characters, date = self.matchData.date},
					}
				},
				Div{
					classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-4'},
					children = {
						PlayerStat{
							title = {KDA_ICON, 'KDA'},
							data = Array.interleave({
								player.extradata.kills,
								player.extradata.deaths,
								player.extradata.assists
							}, SPAN_SLASH)
						},
						PlayerStat{
							title = {
								IconImage{
									imageLight = 'Lol stat icon cs.png',
									caption = 'CS per minute',
									size = 'x16px',
									link = ''
								},
								'CSM'
							},
							data = calculateStatPerMinute(player.extradata.creepscore, player.extradata.gameLength)
						},
						PlayerStat{
							title = {GOLD_ICON, 'GPM'},
							data = calculateStatPerMinute(player.extradata.gold, player.extradata.gameLength)
						},
						PlayerStat{
							title = {
								IconFa{
									iconName = 'damage',
									additionalClasses = {'fa-flip-both'},
									hover = 'Damage per minute'
								},
								'DPM'
							},
							data = calculateStatPerMinute(player.extradata.damage, player.extradata.gameLength)
						}
					}
				}
			)
		}
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			renderOverallTeamStats(),
			HtmlWidgets.H3{children = 'Overall Player Performance'},
			Div{
				classes = {'match-bm-players-wrapper'},
				children = Array.map(self.opponents, function (opponent)
					return Div{
						classes = {'match-bm-players-team'},
						children = WidgetUtil.collect(
							Div{
								classes = {'match-bm-players-team-header'},
								children = opponent.iconDisplay
							},
							Array.map(
								Array.sortBy(opponent.players, function (player)
									if Logic.isEmpty(player.extradata.role) then
										return -1
									end
									return InGameRoles[player.extradata.role].sortOrder
								end),
								renderPlayerOverallPerformance
							)
						)
					}
				end)
			}
		)
	}
end

---@private
---@param props {finished: boolean, data: {kills: integer, deaths: integer, assists: integer, gold: number?,
---towers: integer, inhibitors: integer, grubs: integer?, heralds: integer?, atakhans: integer?, dragons: integer?,
---barons: integer?}[]}
---@return MatchPageStatsList
function MatchPage._buildTeamStatsList(props)
	return StatsList{
		finished = props.finished,
		data = {
			{
				icon = KDA_ICON,
				name = 'KDA',
				team1Value = Array.interleave({
					props.data[1].kills,
					props.data[1].deaths,
					props.data[1].assists
				}, SPAN_SLASH),
				team2Value = Array.interleave({
					props.data[2].kills,
					props.data[2].deaths,
					props.data[2].assists
				}, SPAN_SLASH)
			},
			{
				icon = GOLD_ICON,
				name = 'Gold',
				team1Value = MatchPage.abbreviateNumber(props.data[1].gold),
				team2Value = MatchPage.abbreviateNumber(props.data[2].gold)
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon tower.png', link = ''},
				name = 'Towers',
				team1Value = props.data[1].towers,
				team2Value = props.data[2].towers
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon inhibitor.png', link = ''},
				name = 'Inhibitors',
				team1Value = props.data[1].inhibitors,
				team2Value = props.data[2].inhibitors
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon grub.png', link = ''},
				name = 'Void Grubs',
				team1Value = props.data[1].grubs,
				team2Value = props.data[2].grubs
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon herald.png', link = ''},
				name = 'Rift Heralds',
				team1Value = props.data[1].heralds,
				team2Value = props.data[2].heralds
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon atakhan.png', link = ''},
				name = 'Atakhan',
				team1Value = props.data[1].atakhans,
				team2Value = props.data[2].atakhans
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon dragon.png', link = ''},
				name = 'Dragons',
				team1Value = props.data[1].dragons,
				team2Value = props.data[2].dragons
			},
			{
				icon = IconImage{imageLight = 'Lol stat icon baron.png', link = ''},
				name = 'Barons',
				team1Value = props.data[1].barons,
				team2Value = props.data[2].barons
			},
		}
	}
end

---@param game LoLMatchPageGame
---@return Widget
function MatchPage:renderGame(game)
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self:_renderGameOverview(game),
			self:_renderDraft(game),
			self:_renderTeamStats(game),
			self:_renderPlayersPerformance(game)
		)
	}
end

---@private
---@param game LoLMatchPageGame
---@return Widget[]
function MatchPage:_buildGameResultSummary(game)
	return {
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
						children = self:_buildGameResultSummary(game)
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
---@return Widget[]
function MatchPage:_renderDraft(game)
	return {
		HtmlWidgets.H3{children = 'Draft'},
		Div{
			classes = {'match-bm-lol-game-veto'},
			children = {
				Div{
					classes = {'match-bm-lol-game-veto-overview'},
					children = Array.map({1, 2}, function (teamIndex)
						return self:_renderGameTeamVetoOverview(game, teamIndex)
					end)
				},
				GeneralCollapsible{
					title = 'Draft Order',
					classes = {'match-bm-lol-game-veto-order'},
					shouldCollapse = true,
					collapseAreaClasses = {'match-bm-lol-game-veto-order-list'},
					children = {
						self:_renderGameTeamVetoOrder(game, 1),
						self:_renderGameTeamVetoOrder(game, 2),
					}
				},
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
				classes = {'match-bm-game-veto-overview-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-overview-team-veto'},
				children = {
					VetoRow{
						vetoType = 'pick',
						side = game.teams[teamIndex].side,
						vetoItems = Array.map(game.teams[teamIndex].picks, function (pick)
							return VetoItem{
								characterIcon = self:getCharacterIcon(pick),
							}
						end)
					},
					VetoRow{
						vetoType = 'ban',
						vetoItems = Array.map(game.teams[teamIndex].bans, function (ban)
							return VetoItem{
								characterIcon = self:getCharacterIcon(ban.character),
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
	local teamVetoGroups = game.vetoGroups[teamIndex]
	return Div{
		classes = {'match-bm-lol-game-veto-order-team'},
		children = {
			Div{
				classes = {'match-bm-lol-game-veto-order-team-header'},
				children = self.opponents[teamIndex].iconDisplay
			},
			Div{
				classes = {'match-bm-lol-game-veto-order-team-choices'},
				children = Array.map(teamVetoGroups or {}, function (vetoGroup)
					return VetoRow{
						vetoType = vetoGroup[1].type,
						side = game.teams[teamIndex].side,
						vetoItems = Array.map(vetoGroup, function (veto)
							return VetoItem{
								characterIcon = self:getCharacterIcon(veto.character),
								vetoNumber = veto.vetoNumber
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
						Div{
							classes = {'match-bm-team-stats-list-cell'},
							children = self:isBestOfOne() and self:_buildGameResultSummary(game) or self:getTournamentIcon()
						},
						Div{
							classes = {'match-bm-lol-team-stats-header-team'},
							children = self.opponents[2].iconDisplay
						}
					}
				},
				MatchPage._buildTeamStatsList{
					finished = game.finished,
					data = Array.map(game.opponents, Operator.property('stats'))
				}
			}
		}
	}
end

---@private
---@param game LoLMatchPageGame
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
---@param game LoLMatchPageGame
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
---@param game LoLMatchPageGame
---@param teamIndex integer
---@param player table
---@return Widget
function MatchPage:_renderPlayerPerformance(game, teamIndex, player)
	return Div{
		classes = {'match-bm-players-player match-bm-players-player--col-3'},
		children = {
			PlayerDisplay{
				characterIcon = self:getCharacterIcon(player.character),
				characterName = player.character,
				side = game.teams[teamIndex].side,
				roleIcon = IconImage{
					imageLight = 'Lol role ' .. player.role .. ' icon darkmode.svg',
					caption = String.upperCaseFirst(player.role),
					link = ''
				},
				playerLink = player.player,
				playerName = player.displayName or player.player
			},
			MatchPage._buildPlayerLoadout(player),
			Div{
				classes = {'match-bm-players-player-stats match-bm-players-player-stats--col-4'},
				children = {
					PlayerStat{
						title = {KDA_ICON, 'KDA'},
						data = Array.interleave({
							player.kills, player.deaths, player.assists
						}, SPAN_SLASH)
					},
					PlayerStat{
						title = {
							IconImage{
								imageLight = 'Lol stat icon cs.png',
								caption = 'CS',
								size = 'x16px',
								link = ''
							},
							'CS'
						},
						data = player.creepscore
					},
					PlayerStat{
						title = {GOLD_ICON, 'Gold'},
						data = MatchPage.abbreviateNumber(player.gold)
					},
					PlayerStat{
						title = {
							IconFa{iconName = 'damage', additionalClasses = {'fa-flip-both'}},
							'Damage'
						},
						data = player.damagedone
					}
				}
			}
		}
	}
end

---@private
---@param props {prefix: string, name: string, caption: string?}
---@return Widget
function MatchPage._generateLoadoutImage(props)
	return IconImage{
		imageLight = props.prefix .. ' ' .. props.name .. '.png',
		caption = props.caption or props.name,
		link = '',
		size = LOADOUT_ICON_SIZE,
	}
end

---@private
---@param runeName string
---@return Widget
MatchPage._generateRuneImage = FnUtil.memoize(function (runeName)
	return MatchPage._generateLoadoutImage{prefix = 'Rune', name = runeName}
end)

---@private
---@param spellName string
---@return Widget
MatchPage._generateSpellImage = FnUtil.memoize(function (spellName)
	return MatchPage._generateLoadoutImage{prefix = 'Summoner spell', name = spellName}
end)

---@private
---@param itemName string
---@return Widget
MatchPage._generateItemImage = FnUtil.memoize(function (itemName)
	local isDefaultItem = itemName == DEFAULT_ITEM
	return Div{
		classes = {'match-bm-players-player-loadout-item'},
		children = MatchPage._generateLoadoutImage{
			prefix = 'Lol item',
			name = itemName,
			caption = isDefaultItem and 'Empty' or itemName,
		}
	}
end)

---@private
---@param player table
---@return Widget
function MatchPage._buildPlayerLoadout(player)
	return Div{
		classes = {'match-bm-players-player-loadout'},
		children = {
			Div{
				classes = {'match-bm-lol-players-player-loadout-rs-wrap'},
				children = {
					Div{
						classes = {'match-bm-lol-players-player-loadout-rs'},
						children = Array.map(
							{player.runeKeystone, player.runes.secondary.tree},
							MatchPage._generateRuneImage
						)
					},
					Div{
						classes = {'match-bm-lol-players-player-loadout-rs'},
						children = Array.map(player.spells, MatchPage._generateSpellImage)
					}
				}
			},
			Div{
				classes = {'match-bm-players-player-loadout-items'},
				children = Array.map(player.items, MatchPage._generateItemImage)
			}
		}
	}
end

function MatchPage.getPoweredBy()
	return 'SAP logo.svg'
end

return MatchPage
