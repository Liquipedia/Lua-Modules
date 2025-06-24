---
-- @Liquipedia
-- page=Module:Widget/ThisDay/Tournament
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local HEADER = HtmlWidgets.H3{children = 'Tournaments'}
local TODAY = os.date("*t")

---@class ThisDayTournamentParameters: ThisDayParameters
---@field hideIfEmpty boolean?

---@class ThisDayTournament: Widget
---@operator call(table): ThisDayTournament
---@field props ThisDayTournamentParameters
local ThisDayTournament = Class.new(Widget)
ThisDayTournament.defaultProps = {
	month = TODAY.month,
	day = TODAY.day
}

---@return Widget[]
function ThisDayTournament:render()
	return WidgetUtil.collect(
		HEADER,
		self:_generateList()
	)
end

---@private
---@return string|(string|Widget)[]
function ThisDayTournament:_generateList()
	local month = self.props.month
	local day = self.props.day
	assert(month, 'Month not specified')
	assert(day, 'Day not specified')

	local tournamentWinData = ThisDayQuery.tournament(month, day)

	if Logic.isEmpty(tournamentWinData) then
		return 'No tournament ended on this date'
	end
	local _, byYear = Array.groupBy(tournamentWinData, function(placement) return placement.date:sub(1, 4) end)

	local display = {}
	for year, yearData in Table.iter.spairs(byYear) do
		Array.appendWith(display,
			HtmlWidgets.H4{
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
---@param yearData placement[]
---@return Widget?
function ThisDayTournament._displayWins(yearData)
	local display = Array.map(yearData, function (placement)
		local displayName = Logic.emptyOr(
			placement.shortname,
			placement.tournament,
			string.gsub(placement.pagename, '_', ' ')
		)

		local row = {
			LeagueIcon.display{
				icon = placement.icon,
				iconDark = placement.icondark,
				link = placement.pagename,
				date = placement.date,
				series = placement.series,
				name = placement.shortnae,
			},
			' ',
			Link{ link = placement.pagename, children = displayName },
			' won by '
		}

		local opponent = Opponent.fromLpdbStruct(placement)

		if not opponent then
			mw.logObject(placement)
		end
		return Array.append(row, OpponentDisplay.InlineOpponent{opponent = opponent})
	end)

	return UnorderedList{ children = display }
end

return ThisDayTournament
