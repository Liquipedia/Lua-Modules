---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local SummaryHelper = Lua.import('Module:Summary/Util')
local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local WidgetUtil = Lua.import('Module:Widget/Util')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/Ffa/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class ApexMatchGroupUtilMatch: MatchGroupUtilMatch
---@field games ApexMatchGroupUtilGame[]

local PLACEMENT_BG = {
	'cell--gold',
	'cell--silver',
	'cell--bronze',
	'cell--copper',
}

local STATUS_ICONS = {
	-- Normal Status
	up = 'fas fa-chevron-double-up',
	stayup = 'fas fa-chevron-up',
	stay = 'fas fa-equals',
	staydown = 'fas fa-chevron-down',
	down = 'fas fa-skull',

	-- Special Status for Match Point matches
	trophy = 'fas fa-trophy',
	matchpoint = 'fad fa-diamond',
}

local OVERVIEW_COLUMNS = {
	{
		class = 'cell--status',
		show = function(match)
			return Table.isNotEmpty(match.extradata.status)
		end,
		header = {
			value = '',
		},
		row = {
			class = function (opponent)
				return 'bg-' .. (opponent.advanceBg or '')
			end,
			value = function (opponent, idx)
				local status = opponent.placementStatus
				if STATUS_ICONS[status] then
					return '<i class="' .. STATUS_ICONS[status] ..'"></i>'
				end
			end,
		},
	},
	{
		sortable = true,
		sortType = 'rank',
		class = 'cell--rank',
		iconClass = 'fas fa-hashtag',
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
		iconClass = 'fas fa-users',
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
				}
			end,
		},
	},
	{
		sortable = true,
		sortType = 'total-points',
		class = 'cell--total-points',
		iconClass = 'fas fa-star',
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
		iconClass = 'fad fa-diamond',
		show = function(match)
				return match.matchPointThreadhold
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
local GAME_COLUMNS = {
	{
		class = 'panel-table__cell__game-placement',
		iconClass = 'fas fa-trophy-alt',
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
		class = 'panel-table__cell__game-kills',
		iconClass = 'fas fa-skull',
		header = {
			value = 'K',
		},
		row = {
			value = function (opponent)
				return opponent.scoreBreakdown.kills
			end,
		},
	},
}

---@param props {bracketId: string, matchId: string}
---@return Widget
function CustomMatchSummary.getByMatchId(props)
	---@class ApexMatchGroupUtilMatch
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	match.matchPointThreadhold = Table.extract(match.extradata.scoring, 'matchPointThreadhold')
	CustomMatchSummary._opponents(match)
	local scoringData = SummaryHelper.createScoringData(match)

	return HtmlWidgets.Fragment{children = {
		MatchSummaryWidgets.Header{matchId = match.matchId, games = match.games},
		MatchSummaryWidgets.Tab{
			matchId = match.matchId,
			idx = 0,
			children = {
				CustomMatchSummary._createSchedule(match),
				MatchSummaryWidgets.PointsDistribution{killScore = scoringData.kill, placementScore = scoringData.placement},
				CustomMatchSummary._createMatchStandings(match)
			}
		}
	}}
end

function CustomMatchSummary._opponents(match)
	-- Add games opponent data to the match opponent
	Array.forEach(match.opponents, function (opponent, idx)
		opponent.games = Array.map(match.games, function (game)
			return game.opponents[idx]
		end)
	end)

	if match.matchPointThreadhold then
		Array.forEach(match.opponents, function(opponent)
			local matchPointReachedIn
			local sum = opponent.extradata.startingpoints or 0
			for gameIdx, game in ipairs(opponent.games) do
				if sum >= match.matchPointThreadhold then
					matchPointReachedIn = gameIdx
					break
				end
				sum = sum + (game.score or 0)
			end
			opponent.matchPointReachedIn = matchPointReachedIn
		end)
	end

	-- Sort match level based on final placement & score
	Array.sortInPlaceBy(match.opponents, FnUtil.identity, SummaryHelper.placementSortFunction)

	-- Set the status of the current placement
	Array.forEach(match.opponents, function(opponent, idx)
		opponent.placementStatus = match.extradata.status[idx]
	end)
end

---@param match table
---@return Widget
function CustomMatchSummary._createSchedule(match)
	return MatchSummaryWidgets.ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule', children = {
		HtmlWidgets.Ul{
			classes = {'panel-content__game-schedule'},
			children = Array.map(match.games, function (game, idx)
				return HtmlWidgets.Li{
					children = {
						HtmlWidgets.Span{
							children = MatchSummaryWidgets.CountdownIcon{
								game = game,
								additionalClasses = {'panel-content__game-schedule__icon'}
							},
						},
						HtmlWidgets.Span{
							classes = {'panel-content__game-schedule__title'},
							children = 'Game ' .. idx .. ':',
						},
						HtmlWidgets.Div{
							classes = {'panel-content__game-schedule__container'},
							children = SummaryHelper.gameCountdown(game),
						},
					},
				}
			end)
		}
	}}
end

---@param match table
---@return Html
function CustomMatchSummary._createMatchStandings(match)
	local rows = Array.map(match.opponents, function (opponent, index)
		local children = Array.map(OVERVIEW_COLUMNS, function(column)
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
					children = Array.map(GAME_COLUMNS, function(column)
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

	local cells = Array.map(OVERVIEW_COLUMNS, function(column)
		return MatchSummaryWidgets.TableHeaderCell{
			class = column.class,
			iconClass = column.iconClass,
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
									SummaryHelper.gameCountdown(game),
								}
							},
							HtmlWidgets.Div{
								classes = {'panel-table__cell__game-details'},
								children = Array.map(GAME_COLUMNS, function(column)
									return MatchSummaryWidgets.TableHeaderCell{
										class = column.class,
										iconClass = column.iconClass,
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

return CustomMatchSummary
