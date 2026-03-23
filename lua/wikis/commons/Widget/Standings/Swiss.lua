---
-- @Liquipedia
-- page=Module:Widget/Standings/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Label = Lua.import('Module:Widget/Basic/Label')
local MatchOverview = Lua.import('Module:Widget/Standings/MatchOverview')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class StandingsSwissWidgetProps
---@field standings StandingsModel

---@class StandingsSwissWidget: Widget
---@operator call(StandingsSwissWidgetProps): StandingsSwissWidget
---@field props StandingsSwissWidgetProps
local StandingsSwissWidget = Class.new(Widget)

---@return Widget?
function StandingsSwissWidget:render()
	if not self.props.standings then
		return
	end

	local standings = self.props.standings
	local lastRound = standings.rounds[#standings.rounds]

	return TableWidgets.Table{
		classes = {'standings-swiss'},
		title = Logic.nilIfEmpty(standings.title),
		columns = self:_buildColumnDefinitions(),
		children = WidgetUtil.collect(
			-- Column Header
			self:_headerRow(),
			-- Rows
			TableWidgets.TableBody{children = Array.map(lastRound.opponents, function(slot)
				return self:_createRow(slot)
			end)}
		)
	}
end

---@private
---@return table[]
function StandingsSwissWidget:_buildColumnDefinitions()
	local standings = self.props.standings
	return WidgetUtil.collect(
		{align = 'left'},
		{align = 'left'},
		Array.map(standings.tiebreakers, function(tiebreaker)
			if not tiebreaker.title then
				return
			end
			return {align = 'center'}
		end),
		Array.map(standings.rounds, function(round)
			return {align = 'center'}
		end)
	)
end

---@private
---@return Widget
function StandingsSwissWidget:_headerRow()
	local standings = self.props.standings

	---@param text string?
	---@return Widget
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('#'),
			makeHeaderCell('Participant'),
			Array.map(standings.tiebreakers, function(tiebreaker)
				if not tiebreaker.title then
					return
				end
				return HtmlWidgets.Th{children = tiebreaker.title}
			end),
			Array.map(standings.rounds, function(round)
				return HtmlWidgets.Th{children = round.title}
			end)
		)}
	}}
end

---@private
---@param slot StandingsEntryModel
---@return Widget
function StandingsSwissWidget:_createRow(slot)
	local standings = self.props.standings
	return TableWidgets.Row{
		attributes = {['data-position-status'] = slot.positionStatus},
		children = WidgetUtil.collect(
			TableWidgets.Cell{
				children = Label{
					children = slot.placement,
					attributes = {['data-placement-type'] = slot.definitiveStatus},
					labelScheme = 'placement',
				},
			},
			TableWidgets.Cell{
				children = OpponentDisplay.BlockOpponent{
					opponent = slot.opponent,
					overflow = 'ellipsis',
					teamStyle = 'hybrid',
					showPlayerTeam = true,
				}
			},
			Array.map(standings.tiebreakers, function(tiebreaker, tiebreakerIndex)
				if not tiebreaker.title then
					return
				end
				return TableWidgets.Cell{
					css = {['font-weight'] = tiebreakerIndex == 1 and 'bold' or nil},
					children = slot.tiebreakerValues[tiebreaker.id] and slot.tiebreakerValues[tiebreaker.id].display or ''
				}
			end),
			Array.map(standings.rounds, function(columnRound)
				local entry = Array.find(columnRound.opponents, function(columnSlot)
					return Opponent.same(columnSlot.opponent, slot.opponent)
				end)
				if not entry then
					return TableWidgets.Cell{}
				end
				local match = entry.match
				if not match then
					return TableWidgets.Cell{}
				end

				local opposingOpponentIndex = Array.indexOf(match.opponents, function(opponent)
					return not Opponent.same(entry.opponent, opponent)
				end)
				if not entry.match.opponents[opposingOpponentIndex] then
					return TableWidgets.Cell{}
				end

				return TableWidgets.Cell{children = MatchOverview{
					match = match,
					showOpponent = opposingOpponentIndex,
				}}
			end)
		),
	}
end

return StandingsSwissWidget
