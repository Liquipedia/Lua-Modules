---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Base/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local MatchSummaryFfa = {}

local PLACEMENT_BG = {
	'cell--gold',
	'cell--silver',
	'cell--bronze',
	'cell--copper',
}

local STATUS_ICONS = {
	-- Normal Status
	up = 'standings_up',
	stayup = 'standings_stayup',
	stay = 'standings_stay',
	staydown = 'standings_staydown',
	down = 'standings_down',

	-- Special Status for Match Point matches
	trophy = 'firstplace',
	matchpoint = 'matchpoint',
}

local MATCH_OVERVIEW_COLUMNS = {
	{
		class = 'cell--status',
		show = function(match)
			return Table.any(match.extradata.placementinfo or {}, function(_, value)
				return value.status ~= nil
			end)
		end,
		header = {
			value = '',
		},
		row = {
			class = function (opponent)
				return 'bg-' .. (opponent.advanceBg or '')
			end,
			value = function (opponent, idx)
				if not STATUS_ICONS[opponent.placementStatus] then
					return
				end
				return IconWidget{
					iconName = STATUS_ICONS[opponent.placementStatus],
				}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'rank',
		class = 'cell--rank',
		icon = 'rank',
		header = {
			value = 'Rank',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.placement ~= -1 and opponent.placement or idx
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local placementDisplay = tostring(MatchSummaryWidgets.RankRange{rankStart = place})
				return HtmlWidgets.Fragment{children = {
					MatchSummaryWidgets.Trophy{place = place, additionalClasses = {'panel-table__cell-icon'}},
					HtmlWidgets.Span{children = placementDisplay},
				}}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'team',
		class = 'cell--team',
		icon = 'team',
		header = {
			value = 'Participant',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.name
			end,
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.BlockOpponent{
					opponent = opponent,
					showLink = true,
					overflow = 'ellipsis',
					teamStyle = 'hybrid',
					showPlayerTeam = true,
				}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'total-points',
		class = 'cell--total-points',
		icon = 'points',
		header = {
			value = 'Total Points',
			mobileValue = 'Pts.',
		},
		sortVal = {
			value = function (opponent, idx)
				return OpponentDisplay.InlineScore(opponent)
			end,
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.InlineScore(opponent)
			end,
		},
	},
	{
		sortable = true,
		sortType = 'match-points',
		class = 'cell--match-points',
		icon = 'matchpoint',
		show = function(match)
				return (match.extradata.settings or {}).matchPointThreshold
		end,
		header = {
			value = 'MPe Game',
			mobileValue = 'MPe',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.matchPointReachedIn or 999 -- High number that should not be exceeded
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.matchPointReachedIn and "Game " .. opponent.matchPointReachedIn or nil
			end,
		},
	},
}
local GAME_OVERVIEW_COLUMNS = {
	{
		show = function(match)
			return (match.extradata.settings or {}).showGameDetails
		end,
		class = 'panel-table__cell__game-placement',
		icon = 'placement',
		header = {
			value = 'P',
		},
		row = {
			class = function (opponent)
				return PLACEMENT_BG[opponent.placement]
			end,
			value = function (opponent)
				local placementDisplay
				if opponent.status and opponent.status ~= 'S' then
					placementDisplay = '-'
				else
					placementDisplay = tostring(MatchSummaryWidgets.RankRange{rankStart = opponent.placement})
				end
				return HtmlWidgets.Fragment{children = {
					MatchSummaryWidgets.Trophy{place = opponent.placement, additionalClasses = {'panel-table__cell-icon'}},
					HtmlWidgets.Span{
						classes = {'panel-table__cell-game__text'},
						children = placementDisplay,
					}
				}}
			end,
		},
	},
	{
		show = function(match)
			if (match.extradata.settings or {}).showGameDetails == false then
				return false
			end
			return Table.any(match.extradata.placementinfo or {}, function(_, value)
				return value.killPoints ~= nil
			end)
		end,
		class = 'panel-table__cell__game-kills',
		icon = 'kills',
		header = {
			value = 'K',
		},
		row = {
			value = function (opponent)
				return opponent.scoreBreakdown.kills
			end,
		},
	},
	{
		show = function(match)
			return not (match.extradata.settings or {}).showGameDetails
		end,
		class = 'panel-table__cell__game-total-points',
		icon = 'points',
		header = {
			value = 'Pts.',
		},
		row = {
			value = function (opponent)
				return opponent.score
			end,
		},
	},
}
local GAME_STANDINGS_COLUMNS = {
	{
		sortable = true,
		sortType = 'rank',
		class = 'cell--rank',
		icon = 'rank',
		header = {
			value = 'Rank',
		},
		sortVal = {
			value = function (opponent, idx)
				if opponent.placement == -1 or opponent.status ~= 'S' then
					return idx
				end
				return opponent.placement
			end,
		},
		row = {
			value = function (opponent, idx)
				local place = opponent.placement ~= -1 and opponent.placement or idx
				local placementDisplay
				if opponent.status and opponent.status ~= 'S' then
					placementDisplay = '-'
				else
					placementDisplay = tostring(MatchSummaryWidgets.RankRange{rankStart = place})
				end
				return HtmlWidgets.Fragment{children = {
					MatchSummaryWidgets.Trophy{place = place, additionalClasses = {'panel-table__cell-icon'}},
					HtmlWidgets.Span{children = placementDisplay},
				}}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'team',
		class = 'cell--team',
		icon = 'team',
		header = {
			value = 'Team',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.name
			end,
		},
		row = {
			value = function (opponent, idx)
				return OpponentDisplay.BlockOpponent{
					opponent = opponent,
					showLink = true,
					overflow = 'ellipsis',
					teamStyle = 'hybrid',
					showPlayerTeam = true,
					showPlayerFaction = true,
				}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'total-points',
		class = 'cell--total-points',
		icon = 'points',
		header = {
			value = 'Total Points',
			mobileValue = 'Pts.',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.score
			end,
		},
	},
	{
		show = function(game)
			return (game.extradata.settings or {}).showGameDetails
		end,
		sortable = true,
		sortType = 'placements',
		class = 'cell--placements',
		icon = 'placement',
		header = {
			value = 'Placement Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.placePoints
			end,
		},
	},
	{
		show = function(game)
			return (game.extradata.settings or {}).showGameDetails
		end,
		sortable = true,
		sortType = 'kills',
		class = 'cell--kills',
		icon = 'kills',
		header = {
			value = 'Kill Points',
		},
		sortVal = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
		row = {
			value = function (opponent, idx)
				return opponent.scoreBreakdown.killPoints
			end,
		},
	},
}

---@param opponent1 table
---@param opponent2 table
---@return boolean
function MatchSummaryFfa.placementSortFunction(opponent1, opponent2)
	if opponent1.placement and opponent2.placement and opponent1.placement ~= opponent2.placement then
		return opponent1.placement < opponent2.placement
	end
	if opponent1.status ~= 'S' and opponent2.status == 'S' then
		return false
	end
	if opponent2.status ~= 'S' and opponent1.status == 'S' then
		return true
	end
	if opponent1.score and opponent2.score and opponent1.score ~= opponent2.score then
		return opponent1.score > opponent2.score
	end
	return (opponent1.name or ''):lower() < (opponent2.name or ''):lower()
end

---@param match table
---@return {kill: number, placement: {rangeStart: integer, rangeEnd: integer, score:number}[]}
function MatchSummaryFfa.createScoringData(match)
	local scoreSettings = match.extradata.placementinfo

	local newScores = {}
	local lastData = {}
	for placement, placementData in ipairs(scoreSettings or {}) do
		local currentData = {
			killPoints = placementData.killPoints,
			placementPoints = placementData.placementPoints,
		}
		if Table.deepEquals(lastData, currentData) then
			newScores[#newScores].rangeEnd = newScores[#newScores].rangeEnd + 1
		else
			table.insert(newScores, {
				rangeStart = placement,
				rangeEnd = placement,
				killScore = currentData.killPoints,
				placementScore = currentData.placementPoints,
			})
		end
		lastData = currentData
	end
	return newScores
end

---@param match table
---@return MatchSummaryFfaTable
function MatchSummaryFfa.standardMatch(match)
	local rows = Array.map(match.opponents, function (opponent, index)
		local children = Array.map(MATCH_OVERVIEW_COLUMNS, function(column)
			if column.show and not column.show(match) then
				return
			end
			return MatchSummaryWidgets.TableRowCell{
				class = (column.class or '') .. ' ' .. (column.row.class and column.row.class(opponent) or ''),
				sortable = column.sortable,
				sortType = column.sortType,
				sortValue = column.sortVal and column.sortVal.value(opponent, index) or nil,
				value = column.row.value(opponent, index),
			}
		end)

		local gameRowContainer = HtmlWidgets.Div{
			classes = {'panel-table__cell', 'cell--game-container'},
			attributes = {
				['data-js-battle-royale'] = 'game-container'
			},
			children = Array.map(opponent.games, function(gameOpponent)
				local gameRow = HtmlWidgets.Div{
					classes = {'panel-table__cell', 'cell--game'},
					children = Array.map(GAME_OVERVIEW_COLUMNS, function(column)
						if column.show and not column.show(match) then
							return
						end
						return MatchSummaryWidgets.TableRowCell{
							class = (column.class or '') .. ' ' .. (column.row.class and column.row.class(gameOpponent) or ''),
							value = column.row.value(gameOpponent),
						}
					end)
				}
				return gameRow
			end)
		}
		table.insert(children, gameRowContainer)
		return MatchSummaryWidgets.TableRow{children = children}
	end)

	local cells = Array.map(MATCH_OVERVIEW_COLUMNS, function(column)
		if column.show and not column.show(match) then
			return
		end
		return MatchSummaryWidgets.TableHeaderCell{
			class = column.class,
			icon = column.icon,
			mobileValue = column.header.mobileValue,
			show = column.show,
			sortable = column.sortable,
			sortType = column.sortType,
			value = column.header.value,
		}
	end)

	table.insert(cells, HtmlWidgets.Div{
		classes = {'panel-table__cell', 'cell--game-container-nav-holder'},
		attributes = {
			['data-js-battle-royale'] = 'game-nav-holder'
		},
		children = {
			HtmlWidgets.Div{
				classes = {'panel-table__cell', 'cell--game-container'},
				attributes = {
					['data-js-battle-royale'] = 'game-container'
				},
				children = Array.map(match.games, function(game, idx)
					return HtmlWidgets.Div{
						classes = {'panel-table__cell', 'cell--game'},
						children = {
							HtmlWidgets.Div{
								classes = {'panel-table__cell__game-head'},
								children = {
									HtmlWidgets.Div{
										classes = {'panel-table__cell__game-title'},
										children = {
											MatchSummaryWidgets.CountdownIcon{game = game, additionalClasses = {'panel-table__cell-icon'}},
											HtmlWidgets.Span{
												classes = {'panel-table__cell-text'},
												children = 'Game ' .. idx
											}
										}
									},
									MatchSummaryWidgets.GameCountdown{game = game},
								}
							},
							HtmlWidgets.Div{
								classes = {'panel-table__cell__game-details'},
								children = Array.map(GAME_OVERVIEW_COLUMNS, function(column)
									if column.show and not column.show(match) then
										return
									end
									return MatchSummaryWidgets.TableHeaderCell{
										class = column.class,
										icon = column.icon,
										mobileValue = column.header.mobileValue,
										show = column.show,
										value = column.header.value,
									}
								end)
							}
						}
					}
				end)
			}
		}
	})

	return MatchSummaryWidgets.Table{children = {
		MatchSummaryWidgets.TableHeader{children = cells},
		unpack(rows)
	}}
end

---@param game table
---@return MatchSummaryFfaTable
function MatchSummaryFfa.standardGame(game)
	local rows = Array.map(game.opponents, function (opponent, index)
		local children = Array.map(GAME_STANDINGS_COLUMNS, function(column)
			if column.show and not column.show(game) then
				return
			end
			return MatchSummaryWidgets.TableRowCell{
				class = column.class,
				sortable = column.sortable,
				sortType = column.sortType,
				sortValue = column.sortVal and column.sortVal.value(opponent, index) or nil,
				value = column.row.value(opponent, index),
			}
		end)
		return MatchSummaryWidgets.TableRow{children = children}
	end)

	return MatchSummaryWidgets.Table{children = {
		MatchSummaryWidgets.TableHeader{children = Array.map(GAME_STANDINGS_COLUMNS, function(column)
			if column.show and not column.show(game) then
				return
			end
			return MatchSummaryWidgets.TableHeaderCell{
				class = column.class,
				icon = column.icon,
				mobileValue = column.header.mobileValue,
				sortable = column.sortable,
				sortType = column.sortType,
				value = column.header.value,
			}
		end)},
		unpack(rows)
	}}
end

---@param match table
function MatchSummaryFfa.updateMatchOpponents(match)
	-- Add games opponent data to the match opponent
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.opponents[idx]
		end)
	end)

	local matchPointThreshold = (match.extradata.settings or {}).matchPointThreshold
	if matchPointThreshold then
		Array.forEach(match.opponents, function(opponent)
			local matchPointReachedIn
			local sum = opponent.extradata.startingpoints or 0
			for gameIdx, game in ipairs(opponent.games) do
				if sum >= matchPointThreshold then
					matchPointReachedIn = gameIdx
					break
				end
				sum = sum + (game.score or 0)
			end
			opponent.matchPointReachedIn = matchPointReachedIn
		end)
	end

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, MatchSummaryFfa.placementSortFunction)

	-- Set the status of the current placement
	Array.forEach(match.opponents, function(opponent, idx)
		opponent.placementStatus = ((match.extradata.placementinfo or {})[idx] or {}).status
	end)
end

---@param game table
---@param matchOpponents table[]
function MatchSummaryFfa.updateGameOpponents(game, matchOpponents)
	-- Add match opponent data to game opponent
	game.opponents = Array.map(game.opponents,
		function(gameOpponent, opponentIdx)
			local matchOpponent = matchOpponents[opponentIdx]
			local newGameOpponent = Table.merge(matchOpponent, gameOpponent)
			-- These values are only allowed to come from Game and not Match
			newGameOpponent.placement = gameOpponent.placement
			newGameOpponent.score = gameOpponent.score
			newGameOpponent.status = gameOpponent.status
			return newGameOpponent
		end
	)

	-- Sort game level based on placement
	Array.sortInPlaceBy(game.opponents, FnUtil.identity, MatchSummaryFfa.placementSortFunction)
end

return MatchSummaryFfa
