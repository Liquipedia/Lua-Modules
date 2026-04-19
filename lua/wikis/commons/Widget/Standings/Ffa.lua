---
-- @Liquipedia
-- page=Module:Widget/Standings/Ffa
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Label = Lua.import('Module:Widget/Basic/Label')
local RoundSelector = Lua.import('Module:Widget/Standings/RoundSelector')
local PlacementChange = Lua.import('Module:Widget/Standings/PlacementChange')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local STATUS_TO_DISPLAY = {
	dq = 'DQ',
	nc = '-',
}

---@class StandingsFfaWidgetProps
---@field standings StandingsModel

---@class StandingsFfaWidget: Widget
---@operator call(StandingsFfaWidgetProps): StandingsFfaWidget
---@field props StandingsFfaWidgetProps
local StandingsFfaWidget = Class.new(Widget)

---@return Widget?
function StandingsFfaWidget:render()
	if not self.props.standings then
		return
	end

	local standings = self.props.standings
	local activeRounds = (Array.maxBy(
		Array.filter(standings.rounds, function(round) return round.started end),
		function (round) return round.round end
	) or {round = 0}).round

	local standingsTable = TableWidgets.Table{
		classes = {'standings-ffa'},
		columns = WidgetUtil.collect(
			{align = 'center'},
			self:_showRoundColumns() and {align = 'center'} or nil,
			{align = 'left'},
			Array.map(standings.tiebreakers, function(tiebreaker)
				if not tiebreaker.title then
					return
				end
				return {align = 'center'}
			end),
			self:_showRoundColumns() and Array.map(standings.rounds, function(round)
				return {align = 'center'}
			end) or nil
		),
		title = String.nilIfEmpty(standings.title),
		children = WidgetUtil.collect(
			self:_headerRow(),
			Array.map(standings.rounds, function (round)
				if round.round > activeRounds then
					return
				end
				return self:_createRoundBody(round)
			end)
		)
	}

	if activeRounds == 0 then
		return standingsTable
	end

	local hasFutureRounds = self:_hasFutureRounds()

	return HtmlWidgets.Div{
		classes = {'standings-ffa-wrapper', 'toggle-area', 'toggle-area-' .. activeRounds},
		attributes = {['data-toggle-area'] = activeRounds},
		children = WidgetUtil.collect(
			activeRounds > 0 and RoundSelector{
				rounds = activeRounds,
				hasEnded = not hasFutureRounds,
			} or nil,
			standingsTable
		)
	}
end

---@private
---@return boolean
function StandingsFfaWidget:_hasFutureRounds()
	local standings = self.props.standings
	return not standings.rounds[#standings.rounds].started
end

---@private
---@return boolean
function StandingsFfaWidget:_showRoundColumns()
	local standings = self.props.standings
	return #standings.rounds > 1
end

---@private
---@return Widget
function StandingsFfaWidget:_headerRow()
	local standings = self.props.standings

	---@param text string?
	---@return Widget
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('#'),
			self:_showRoundColumns() and makeHeaderCell() or nil,
			makeHeaderCell('Participant'),
			Array.map(standings.tiebreakers, function(tiebreaker)
				if not tiebreaker.title then
					return
				end
				return makeHeaderCell(tiebreaker.title)
			end),
			self:_showRoundColumns() and Array.map(standings.rounds, function(round)
				return makeHeaderCell(round.title)
			end) or nil
		)}
	}}
end

---@private
---@param round StandingsRound
---@return Widget
function StandingsFfaWidget:_createRoundBody(round)
	local standings = self.props.standings
	return TableWidgets.TableBody{children = Array.map(round.opponents, function (slot)
		return TableWidgets.Row{
			attributes = {
				['data-position-status'] = slot.positionStatus,
				['data-toggle-area-content'] = round.round,
			},
			children = WidgetUtil.collect(
				TableWidgets.Cell{children = Label{
					children = slot.placement,
					attributes = {
						['data-placement-type'] = Logic.nilIfEmpty(slot.definitiveStatus)
					},
					labelScheme = 'placement',
				}},
				self:_showRoundColumns() and TableWidgets.Cell{
					children = PlacementChange{change = slot.positionChangeFromPreviousRound}
				} or nil,
				TableWidgets.Cell{children = OpponentDisplay.BlockOpponent{
					opponent = slot.opponent,
					overflow = 'ellipsis',
					teamStyle = 'hybrid',
					showPlayerTeam = true,
				}},
				Array.map(standings.tiebreakers, function(tiebreaker, tiebreakerIndex)
					if not tiebreaker.title then
						return
					end
					return TableWidgets.Cell{
						css = {['font-weight'] = tiebreakerIndex == 1 and 'bold' or nil},
						children = slot.tiebreakerValues[tiebreaker.id] and slot.tiebreakerValues[tiebreaker.id].display or ''
					}
				end),
				self:_showRoundColumns() and Array.map(standings.rounds, function (columnRound)
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
					return TableWidgets.Cell{children = text}
				end) or nil
			)
		}
	end)}
end

return StandingsFfaWidget
