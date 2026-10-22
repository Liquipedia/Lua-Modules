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
local MatchOverview = Lua.import('Module:Widget/Standings/MatchOverview')
local StandingsCells = Lua.import('Module:Widget/Standings/Cells')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Opponent = Lua.import('Module:Opponent/Custom')
local StandingsDisplayUtil = Lua.import('Module:Standings/DisplayUtil')

local Helpers = {}

---@param props {standings?: StandingsModel}
---@return Renderable?
local function StandingsSwiss(props)
	local standings = props.standings
	if not standings then
		return
	end

	local lastRound = standings.rounds[#standings.rounds]
	local statsToShow = StandingsDisplayUtil.statsToShow(standings)
	local boldStatTitle = StandingsDisplayUtil.boldStatTitle(standings)

	return TableWidgets.Table{
		classes = {'standings-swiss'},
		title = Logic.nilIfEmpty(standings.title),
		columns = Helpers.buildColumnDefinitions(standings, statsToShow),
		children = WidgetUtil.collect(
			-- Column Header
			Helpers.headerRow(standings, statsToShow),
			-- Rows
			TableWidgets.TableBody{children = Array.map(lastRound.opponents, function(slot)
				return Helpers.createRow(standings, slot, statsToShow, boldStatTitle)
			end)}
		),
		striped = false
	}
end

---@private
---@param standings StandingsModel
---@param statsToShow StandingsAdditionalStat[]
---@return table[]
function Helpers.buildColumnDefinitions(standings, statsToShow)
	return WidgetUtil.collect(
		{align = 'left'},
		{align = 'left'},
		StandingsCells.statColumns(statsToShow),
		Array.rep({align = 'center'}, #standings.rounds)
	)
end

---@private
---@param standings StandingsModel
---@param statsToShow StandingsAdditionalStat[]
---@return Renderable
function Helpers.headerRow(standings, statsToShow)
	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			StandingsCells.header('#'),
			StandingsCells.header('Participant'),
			StandingsCells.statHeaders(statsToShow),
			Array.map(standings.rounds, function(round)
				return StandingsCells.header(round.title)
			end)
		)}
	}}
end

---@private
---@param standings StandingsModel
---@param slot StandingsEntryModel
---@param statsToShow StandingsAdditionalStat[]
---@param boldStatTitle string?
---@return Renderable
function Helpers.createRow(standings, slot, statsToShow, boldStatTitle)
	return TableWidgets.Row{
		attributes = {['data-position-status'] = slot.positionStatus},
		children = WidgetUtil.collect(
			StandingsCells.placement(slot),
			StandingsCells.participant(slot),
			StandingsCells.stats(slot, statsToShow, boldStatTitle),
			Array.map(standings.rounds, function(columnRound)
				local entry = Array.find(columnRound.opponents, function(columnSlot)
					return Opponent.same(columnSlot.opponent, slot.opponent)
				end)
				if not entry then
					return TableWidgets.Cell{}
				end
				if not entry.match or not entry.matchOpponentIndex then
					return TableWidgets.Cell{}
				end

				return TableWidgets.Cell{children = MatchOverview{
					match = entry.match,
					opponentIndex = entry.matchOpponentIndex,
				}}
			end)
		),
	}
end

return Component.component(StandingsSwiss)
