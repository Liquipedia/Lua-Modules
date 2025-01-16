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

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class StandingsFfaWidget: Widget
---@operator call(table): StandingsFfaWidget

local StandingsFfaWidget = Class.new(Widget)
StandingsFfaWidget.defaultProps = {
}

---@return Widget?
function StandingsFfaWidget:render()
	if not self.props.standings then
		return
	end

	---@type StandingsModel
	local standings = self.props.standings
	local roundCount = #standings.rounds

	return DataTable{
		wrapperClasses = {'toggle-area', 'toggle-area-' .. roundCount},
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
					HtmlWidgets.Span{
						css = {
							['margin-left'] = '-70px',
							['vertical-align'] = 'middle',
						},
						children = standings.section
					},
					RoundSelector{
						rounds = roundCount,
						hasEnded = true, -- TODO
					},
				},
			}},
			-- Column Header
			HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{children = '#'},
				HtmlWidgets.Th{children = 'Participant'},
				HtmlWidgets.Th{children = 'Points'},
			}},
			-- Rows
			Array.flatMap(standings.rounds, function(round)
				return Array.map(round.opponents, function(slot)
					return HtmlWidgets.Tr{
						children = {
							HtmlWidgets.Td{children = slot.placement},
							HtmlWidgets.Td{children = OpponentDisplay.BlockOpponent{
								opponent = slot.opponent,
								showLink = true,
								overflow = 'ellipsis',
								teamStyle = 'hybrid',
								showPlayerTeam = true,
							}},
							HtmlWidgets.Td{children = 'TODO'},
						},
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
