---
-- @Liquipedia
-- page=Module:Widget/Standings/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local RoundHistory = Lua.import('Module:Widget/Standings/RoundHistory')
local StandingsCells = Lua.import('Module:Widget/Standings/Cells')
local Switch = Lua.import('Module:Widget/Switch')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Opponent = Lua.import('Module:Opponent/Custom')
local StandingsDisplayUtil = Lua.import('Module:Standings/DisplayUtil')

local STATUS_TO_DISPLAY = {
	dq = 'DQ',
	nc = '-',
}

local Helpers = {}

---@param props {standings?: StandingsModel}
---@return Renderable?
local function StandingsFfa(props)
	local standings = props.standings
	if not standings then
		return
	end

	local shownRounds = StandingsDisplayUtil.roundsToShow(standings)
	local statsToShow = StandingsDisplayUtil.statsToShow(standings)
	local boldStatTitle = StandingsDisplayUtil.boldStatTitle(standings)
	-- Also holds the round columns switch, so needed as soon as there is more than one round
	local hasRoundHistory = Helpers._showRoundColumns(standings)

	local standingsTable = TableWidgets.Table{
		classes = {'standings-ffa'},
		columns = WidgetUtil.collect(
			{align = 'center'},
			Helpers._showRoundColumns(standings) and {align = 'center'} or nil,
			{align = 'left'},
			StandingsCells.statColumns(statsToShow),
			Helpers._showRoundColumns(standings) and Array.rep({align = 'center'}, #standings.rounds) or nil
		),
		title = String.nilIfEmpty(standings.title),
		children = WidgetUtil.collect(
			Helpers._headerRow(standings, statsToShow),
			Array.map(standings.rounds, function (round)
				if round.round > shownRounds then
					return
				end
				return Helpers._createRoundBody(standings, round, statsToShow, boldStatTitle, hasRoundHistory)
			end)
		),
		striped = false
	}

	if not hasRoundHistory then
		return standingsTable
	end

	return RoundHistory{
		activeRounds = shownRounds,
		hasEnded = not StandingsDisplayUtil.hasFutureRounds(standings),
		titles = Array.map(standings.rounds, Operator.property('title')),
		controls = {
			Switch{
				switchGroup = 'ffa-detailed-stats',
				label = 'Detailed stats',
			},
		},
		children = standingsTable,
	}
end

---@private
---@param standings StandingsModel
---@return boolean
function Helpers._showRoundColumns(standings)
	return #standings.rounds > 1
end

---@private
---@param standings StandingsModel
---@param statsToShow StandingsAdditionalStat[]
---@return Renderable
function Helpers._headerRow(standings, statsToShow)
	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			StandingsCells.header('#'),
			Helpers._showRoundColumns(standings) and StandingsCells.header() or nil,
			StandingsCells.header('Participant'),
			StandingsCells.statHeaders(statsToShow),
			Helpers._showRoundColumns(standings) and Array.map(standings.rounds, function(round)
				return TableWidgets.CellHeader{
					classes = {'standings-ffa-detail'},
					children = round.title,
				}
			end) or nil
		)}
	}}
end

---@private
---@param standings StandingsModel
---@param round StandingsRound
---@param statsToShow StandingsAdditionalStat[]
---@param boldStatTitle string?
---@param hasRoundHistory boolean
---@return Renderable
function Helpers._createRoundBody(standings, round, statsToShow, boldStatTitle, hasRoundHistory)
	return TableWidgets.TableBody{children = Array.map(round.opponents, function (slot)
		return TableWidgets.Row{
			attributes = {
				['data-position-status'] = slot.positionStatus,
				['data-toggle-area-content'] = hasRoundHistory and round.round or nil,
			},
			children = WidgetUtil.collect(
				StandingsCells.placement(slot),
				Helpers._showRoundColumns(standings) and TableWidgets.Cell{
					children = PlacementChange{change = slot.positionChangeFromPreviousRound}
				} or nil,
				StandingsCells.participant(slot),
				StandingsCells.stats(slot, statsToShow, boldStatTitle),
				Helpers._showRoundColumns(standings) and Array.map(standings.rounds, function (columnRound)
					local text
					if columnRound.round <= round.round then
						local opponent = Array.find(columnRound.opponents, function(columnSlot)
							return Opponent.same(columnSlot.opponent, slot.opponent)
						end)
						if opponent then
							local roundStatus = opponent.specialStatus
							if roundStatus == '' then
								text = opponent.pointsChangeFromPreviousRound
							else
								text = STATUS_TO_DISPLAY[roundStatus]
							end
						end
					end
					return TableWidgets.Cell{
						classes = {'standings-ffa-detail'},
						children = text,
					}
				end) or nil
			)
		}
	end)}
end

return Component.component(StandingsFfa)
