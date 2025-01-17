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

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local RoundSelector = Lua.import('Module:Widget/Standings/RoundSelector')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

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
	local lastFinishedRound = (Array.maxBy(
		Array.filter(standings.rounds, function(round) return round.finished end),
		function (round) return round.round end
	) or {round = 0}).round

	return DataTable{
		wrapperClasses = {'standings-ffa', 'toggle-area', 'toggle-area-' .. lastFinishedRound},
		classes = {'wikitable-bordered', 'wikitable-striped'},
		attributes = {['data-toggle-area'] = lastFinishedRound},
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
									rounds = lastFinishedRound,
									hasEnded = standings.rounds[#standings.rounds].finished,
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
				Array.map(standings.rounds, function(round)
					return HtmlWidgets.Th{children = round.title}
				end)
			)},
			-- Rows
			Array.flatMap(standings.rounds, function(round)
				if round.round > lastFinishedRound then
					return {}
				end
				return Array.map(round.opponents, function(slot)
					local positionBackground = slot.positionStatus and ('bg-' .. slot.positionStatus) or nil
					local teamBackground = slot.definitiveStatus and ('bg-' .. slot.definitiveStatus) or nil
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
							Array.map(standings.rounds, function(columnRound)
								local text = ''
								if columnRound.round <= round.round then
									local newPoints = (Array.find(columnRound.opponents, function(columnSlot)
										return columnSlot.opponent.name == slot.opponent.name
									end).pointsChangeFromPreviousRound)
									if newPoints then
										text = tostring(newPoints)
									else
										text = '-'
									end
								end
								return HtmlWidgets.Td{children = text, css = {['text-align'] = 'center'}}
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

return StandingsFfaWidget
