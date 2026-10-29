---
-- @Liquipedia
-- page=Module:Widget/Standings/Group
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local RoundHistory = Lua.import('Module:Widget/Standings/RoundHistory')
local StandingsCells = Lua.import('Module:Widget/Standings/Cells')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local StandingsDisplayUtil = Lua.import('Module:Standings/DisplayUtil')

local Helpers = {}

---@param props {standings?: StandingsModel, width: number?}
---@return Renderable?
local function StandingsGroup(props)
	local standings = props.standings
	if not standings then
		return
	end

	local shownRounds = StandingsDisplayUtil.roundsToShow(standings)
	local statsToShow = StandingsDisplayUtil.statsToShow(standings)
	local boldStatTitle = StandingsDisplayUtil.boldStatTitle(standings)
	local hasRoundHistory = shownRounds > 1

	local standingsTable = TableWidgets.Table{
		classes = {'standings-group'},
		css = {width = props.width and (props.width .. 'px') or nil},
		title = Logic.nilIfEmpty(standings.title),
		columns = WidgetUtil.collect(
			{align = 'center'},
			Helpers.showPlacementChange(standings) and {align = 'center'} or nil,
			{align = 'left'},
			StandingsCells.statColumns(statsToShow)
		),
		children = WidgetUtil.collect(
			Helpers.headerRow(standings, statsToShow),
			Array.map(Array.sub(standings.rounds, 1, shownRounds), function(round)
				return Helpers.RoundBody{
					standings = standings,
					round = round,
					statsToShow = statsToShow,
					boldStatTitle = boldStatTitle,
					hasRoundHistory = hasRoundHistory,
				}
			end)
		),
		striped = false,
	}

	if not hasRoundHistory then
		return standingsTable
	end

	return RoundHistory{
		activeRounds = shownRounds,
		hasEnded = not StandingsDisplayUtil.hasFutureRounds(standings),
		titles = Array.map(standings.rounds, Operator.property('title')),
		children = standingsTable,
	}
end

---@param standings StandingsModel
---@return boolean
function Helpers.showPlacementChange(standings)
	return #standings.rounds > 1
end

---@param standings StandingsModel
---@param statsToShow StandingsAdditionalStat[]
---@return Renderable
function Helpers.headerRow(standings, statsToShow)
	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			StandingsCells.header('#'),
			Helpers.showPlacementChange(standings) and StandingsCells.header() or nil,
			StandingsCells.header('Participant'),
			StandingsCells.statHeaders(statsToShow)
		)}
	}}
end

---A component, so the rows of a round are only built once the round is rendered
---@param props {standings: StandingsModel, round: StandingsRound, statsToShow: StandingsAdditionalStat[],
---boldStatTitle: string?, hasRoundHistory: boolean}
---@return Renderable
Helpers.RoundBody = Component.component(function(props)
	local standings = props.standings
	local round = props.round
	return TableWidgets.TableBody{children = Array.map(round.opponents, function(slot)
		return TableWidgets.Row{
			attributes = {
				['data-position-status'] = slot.positionStatus,
				['data-toggle-area-content'] = props.hasRoundHistory and round.round or nil,
			},
			children = WidgetUtil.collect(
				StandingsCells.placement(slot),
				Helpers.showPlacementChange(standings) and TableWidgets.Cell{
					children = PlacementChange{change = slot.positionChangeFromPreviousRound}
				} or nil,
				StandingsCells.participant(slot),
				StandingsCells.stats(slot, props.statsToShow, props.boldStatTitle)
			),
		}
	end)}
end)

return Component.component(StandingsGroup)
