---
-- @Liquipedia
-- page=Module:Widget/Standings/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local Label = Lua.import('Module:Widget/Basic/Label')
local MatchOverview = Lua.import('Module:Widget/Standings/MatchOverview')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Helpers = {}

---@param props {standings?: StandingsModel}
---@return Renderable?
local function StandingsSwiss(props)
	local standings = props.standings
	if not standings then
		return
	end

	local lastRound = standings.rounds[#standings.rounds]

	return TableWidgets.Table{
		classes = {'standings-swiss'},
		title = Logic.nilIfEmpty(standings.title),
		columns = Helpers.buildColumnDefinitions(standings),
		children = WidgetUtil.collect(
			-- Column Header
			Helpers.headerRow(standings),
			-- Rows
			TableWidgets.TableBody{children = Array.map(lastRound.opponents, function(slot)
				return Helpers.createRow(standings, slot)
			end)}
		),
		striped = false
	}
end

---@private
---@param standings StandingsModel
---@return table[]
function Helpers.buildColumnDefinitions(standings)
	return WidgetUtil.collect(
		{align = 'left'},
		{align = 'left'},
		Array.map(standings.tiebreakers, function(tiebreaker)
			if not tiebreaker.title then
				return
			end
			return {align = 'center'}
		end),
		Array.rep({align = 'center'}, #standings.rounds)
	)
end

---@private
---@param standings StandingsModel
---@return Renderable
function Helpers.headerRow(standings)
	---@param text string?
	---@return Renderable
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
				return makeHeaderCell(tiebreaker.title)
			end),
			Array.map(standings.rounds, function(round)
				return makeHeaderCell(round.title)
			end)
		)}
	}}
end

---@private
---@param standings StandingsModel
---@param slot StandingsEntryModel
---@return Renderable
function Helpers.createRow(standings, slot)
	return TableWidgets.Row{
		attributes = {['data-position-status'] = slot.positionStatus},
		children = WidgetUtil.collect(
			TableWidgets.Cell{
				children = Label{
					children = slot.placement,
					attributes = {['data-placement-type'] = Logic.nilIfEmpty(slot.definitiveStatus)},
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

return Component.component(StandingsSwiss)
