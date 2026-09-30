---
-- @Liquipedia
-- page=Module:Widget/ThisDay/Tournament
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local ListWidgets = Lua.import('Module:Widget/List')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

local HEADER = Html.H3{children = 'Tournaments'}
local TODAY = os.date("*t")

local ThisDayTournament = {
	defaultProps = {
		month = TODAY.month,
		day = TODAY.day
	}
}

---@param props ThisDayParameters
---@return Renderable[]
function ThisDayTournament.render(props)
	return WidgetUtil.collect(
		HEADER,
		ThisDayTournament._generateList(props)
	)
end

---@private
---@param props ThisDayParameters
---@return Renderable|Renderable[]
function ThisDayTournament._generateList(props)
	local month = props.month
	local day = props.day
	assert(month, 'Month not specified')
	assert(day, 'Day not specified')

	local tournamentWinData = ThisDayQuery.tournament(month, day)

	if Logic.isEmpty(tournamentWinData) then
		return 'No tournament ended on this date'
	end
	local _, byYear = Array.groupBy(tournamentWinData, function(record) return record.date:sub(1, 4) end)

	local display = {}
	for year, yearData in Table.iter.spairs(byYear) do
		Array.appendWith(display,
			Html.H4{
				children = { year }
			},
			'\n',
			ThisDayTournament._displayWins(yearData)
		)
	end
	return display
end

--- Display win rows of a year
---@private
---@param yearData ThisDayTournamentWinRecord[]
---@return VNode
function ThisDayTournament._displayWins(yearData)
	local display = Array.map(yearData, function (record)
		return {
			TournamentTitle{tournament = record.tournament},
			' won by ',
			OpponentDisplay.InlineOpponent{opponent = record.opponent}
		}
	end)

	return ListWidgets.Unordered{ children = display }
end

return Component.component(ThisDayTournament.render, ThisDayTournament.defaultProps)
