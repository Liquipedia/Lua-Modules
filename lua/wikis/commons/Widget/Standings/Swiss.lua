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
	local statsToShow = Helpers.statsColumnsToShow(standings)

	return TableWidgets.Table{
		classes = {'standings-swiss'},
		title = Logic.nilIfEmpty(standings.title),
		columns = Helpers.buildColumnDefinitions(standings, statsToShow),
		children = WidgetUtil.collect(
			-- Column Header
			Helpers.headerRow(standings, statsToShow),
			-- Rows
			TableWidgets.TableBody{children = Array.map(lastRound.opponents, function(slot)
				return Helpers.createRow(standings, slot, statsToShow)
			end)}
		),
		striped = false
	}
end

---@private
---@param standings StandingsModel
---@return {id: string, title: string?}[]
function Helpers.statsColumnsToShow(standings)
	local seenStatsBefore = {}
	return Array.filter(standings.additionalStats, function(tiebreaker)
		if not tiebreaker.title then
			return false
		end
		if seenStatsBefore[tiebreaker.id] then
			return false
		end
		seenStatsBefore[tiebreaker.id] = true
		return true
	end)
end

---@private
---@param standings StandingsModel
---@param statsToShow {id: string, title: string?}[]
---@return table[]
function Helpers.buildColumnDefinitions(standings, statsToShow)
	return WidgetUtil.collect(
		{align = 'left'},
		{align = 'left'},
		Array.map(statsToShow, function(tiebreaker)
			return {align = 'center'}
		end),
		Array.rep({align = 'center'}, #standings.rounds)
	)
end

---@private
---@param standings StandingsModel
---@param statsToShow {id: string, title: string?}[]
---@return Renderable
function Helpers.headerRow(standings, statsToShow)
	---@param text string?
	---@return Renderable
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('#'),
			makeHeaderCell('Participant'),
			Array.map(statsToShow, function(tiebreaker, index)
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
function Helpers.createRow(standings, slot, statsToShow)
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
			Array.map(statsToShow, function(tiebreaker, tiebreakerIndex)
				return TableWidgets.Cell{
					css = {['font-weight'] = tiebreakerIndex == 1 and 'bold' or nil},
					children = slot.additionalStatsValues[tiebreaker.id] and slot.additionalStatsValues[tiebreaker.id].display or ''
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
