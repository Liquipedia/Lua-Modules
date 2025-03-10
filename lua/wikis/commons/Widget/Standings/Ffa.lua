---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings/Ffa
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
local RoundSelector = Lua.import('Module:Widget/Standings/RoundSelector')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local STATUS_TO_DISPLAY = {
	dq = 'DQ',
	nc = '-',
}

---@class StandingsFfaWidget: Widget
---@operator call(table): StandingsFfaWidget

local StandingsFfaWidget = Class.new(Widget)

---@return Widget?
function StandingsFfaWidget:render()
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
	local showRoundColumns = #standings.rounds > 1

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
							HtmlWidgets.Span{
								css = {['position'] = 'absolute', ['left'] = '0', ['top'] = '-6px'},
								children = RoundSelector{
									rounds = activeRounds,
									hasEnded = not hasFutureRounds,
								}
							},
						},
					},
				},
			}},
			-- Column Header
			HtmlWidgets.Tr{children = WidgetUtil.collect(
				HtmlWidgets.Th{children = '#'},
				HtmlWidgets.Th{children = 'Participant'},
				HtmlWidgets.Th{children = ''},
				HtmlWidgets.Th{children = 'Points'},
				showRoundColumns and Array.map(standings.rounds, function(round)
					return HtmlWidgets.Th{children = round.title}
				end) or nil
			)},
			-- Rows
			Array.flatMap(standings.rounds, function(round)
				if round.round > activeRounds then
					return {}
				end
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
								children = PlacementChange{change = slot.positionChangeFromPreviousRound}
							},
							HtmlWidgets.Td{
								classes = {teamBackground},
								children = slot.points,
								css = {['font-weight'] = 'bold', ['text-align'] = 'center'}
							},
							showRoundColumns and Array.map(standings.rounds, function(columnRound)
								local text
								if columnRound.round <= round.round then
									local opponent = Array.find(columnRound.opponents, function(columnSlot)
										return Table.deepEquals(columnSlot.opponent, slot.opponent)
									end)
									local roundStatus = opponent.specialStatus
									if roundStatus == '' then
										text = opponent.pointsChangeFromPreviousRound
									else
										text = STATUS_TO_DISPLAY[roundStatus]
									end
								end
								return HtmlWidgets.Td{children = text, css = {['text-align'] = 'center'}}
							end) or nil
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

return StandingsFfaWidget
