---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local MatchOverview = Lua.import('Module:Widget/Standings/MatchOverview')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class StandingsSwissWidget: Widget
---@operator call(table): StandingsSwissWidget

local StandingsSwissWidget = Class.new(Widget)

---@return Widget?
function StandingsSwissWidget:render()
	if not self.props.standings then
		return
	end

	---@type StandingsModel
	local standings = self.props.standings
	local activeRounds = (Array.maxBy(
		Array.filter(standings.rounds, function(round) return round.started end),
		function (round) return round.round end
	) or {round = 0}).round
	local hasFutureRounds = not standings.rounds[#standings.rounds].started

	return DataTable{
		wrapperClasses = {'standings-ffa', 'toggle-area', 'toggle-area-' .. activeRounds},
		classes = {'wikitable-bordered', 'wikitable-striped'},
		attributes = {['data-toggle-area'] = activeRounds},
		children = WidgetUtil.collect(
			-- Outer header
			HtmlWidgets.Tr{children = HtmlWidgets.Th{
				attributes = {
					colspan = 100,
				},
				children = {
					HtmlWidgets.Div{
						css = {['position'] = 'relative'},
						children = {
							HtmlWidgets.Span{
								children = standings.title
							},
						},
					},
				},
			}},
			-- Column Header
			HtmlWidgets.Tr{children = WidgetUtil.collect(
				HtmlWidgets.Th{children = '#'},
				HtmlWidgets.Th{children = 'Participant'},
				HtmlWidgets.Th{children = 'Matches'},
				Array.map(standings.rounds, function(round)
					return HtmlWidgets.Th{children = round.title}
				end)
			)},
			-- Rows
			Array.flatMap(standings.rounds, function(round)
				return Array.map(round.opponents, function(slot)
					local positionBackground = slot.positionStatus and ('bg-' .. slot.positionStatus) or nil
					local teamBackground
					if not hasFutureRounds and slot.definitiveStatus then
						teamBackground = 'bg-' .. slot.definitiveStatus
					end
					return HtmlWidgets.Tr{
						children = WidgetUtil.collect(
							HtmlWidgets.Td{
								children = {slot.placement, '.'},
								css = {['font-weight'] = 'bold'},
								classes = {positionBackground},
							},
							HtmlWidgets.Td{
								classes = {teamBackground},
								children = OpponentDisplay.BlockOpponent{
									opponent = slot.opponent,
									showLink = true,
									overflow = 'ellipsis',
									teamStyle = 'hybrid',
									showPlayerTeam = true,
								}
							},
							HtmlWidgets.Td{
								classes = {teamBackground},
								children = table.concat({slot.matchWins, slot.matchLosses}, '-'),
								css = {['font-weight'] = 'bold', ['text-align'] = 'center'}
							},
							Array.map(standings.rounds, function(columnRound)
								local entry = Array.find(columnRound.opponents, function(columnSlot)
									return Table.deepEquals(columnSlot.opponent, slot.opponent)
								end)
								if not entry then
									return HtmlWidgets.Td{}
								end

								local match = entry.match
								if not match then
									return HtmlWidgets.Td{}
								end

								local opposingOpponentIndex = Array.indexOf(match.opponents, function(opponent)
									return not Table.deepEquals(opponent, slot.opponent)
								end)
								if not entry.match[opposingOpponentIndex] then
									return HtmlWidgets.Td{}
								end

								return HtmlWidgets.Td{
									children = MatchOverview{
										match = match,
										showOpponent = opposingOpponentIndex,
									},
								}
							end)
						),
						attributes = {
							['data-toggle-area-content'] = round.round,
						}
					}
				end)
			end)
		)
	}
end

return StandingsSwissWidget
