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
	local roundCount = #standings.rounds

	local hasRoundSelector = roundCount > 1

	return DataTable{
		wrapperClasses = {'standings-ffa', 'toggle-area', 'toggle-area-' .. roundCount},
		classes = {'wikitable-bordered', 'wikitable-striped'},
		attributes = {
			['data-toggle-area'] = roundCount,
		},
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
								children = standings.section
							},
							HtmlWidgets.Span{
								css = {['position'] = 'absolute', ['left'] = '0', ['top'] = '-6px'},
								children = RoundSelector{
									rounds = roundCount,
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
				return Array.map(round.opponents, function(slot)
					return HtmlWidgets.Tr{
						children = WidgetUtil.collect(
							HtmlWidgets.Td{children = {slot.placement, '.'}, css = {['font-weight'] = 'bold'}},
							HtmlWidgets.Td{children = OpponentDisplay.BlockOpponent{
								opponent = slot.opponent,
								showLink = true,
								overflow = 'ellipsis',
								teamStyle = 'hybrid',
								showPlayerTeam = true,
							}},
							HtmlWidgets.Td{children = PlacementChange{change = slot.positionChangeFromPreviousRound}},
							HtmlWidgets.Td{children = slot.points, css = {['font-weight'] = 'bold', ['text-align'] = 'center'}},
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
