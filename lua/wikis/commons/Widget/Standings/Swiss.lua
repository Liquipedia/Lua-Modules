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

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local MatchOverview = Lua.import('Module:Widget/Standings/MatchOverview')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
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
	local lastRound = standings.rounds[#standings.rounds]

	return DataTable{
		wrapperClasses = {'standings-ffa'},
		classes = {'wikitable-bordered', 'wikitable-striped'},
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
			Array.map(lastRound.opponents, function(slot)
				local positionBackground = slot.positionStatus and ('bg-' .. slot.positionStatus) or nil
				local teamBackground
				if slot.definitiveStatus then
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
								return Opponent.same(columnSlot.opponent, slot.opponent)
							end)
							if not entry then
								return HtmlWidgets.Td{}
							end
							local match = entry.match
							if not match then
								return HtmlWidgets.Td{}
							end

							local opposingOpponentIndex = Array.indexOf(match.opponents, function(opponent)
								return not Opponent.same(entry.opponent, opponent)
							end)
							if not entry.match.opponents[opposingOpponentIndex] then
								return HtmlWidgets.Td{}
							end

							local bgClassSuffix
							if match.finished then
								local winner = match.winner
								bgClassSuffix = winner == opposingOpponentIndex and 'down' or winner == 0 or 'draw' or 'up'
							end

							return HtmlWidgets.Td{
								classes = {
									bgClassSuffix and ('bg-' .. bgClassSuffix) or nil,
								},
								children = MatchOverview{
									match = match,
									showOpponent = opposingOpponentIndex,
								},
							}
						end)
					),
				}
			end)
		)
	}
end

return StandingsSwissWidget
