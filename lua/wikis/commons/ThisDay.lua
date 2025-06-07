---
-- @Liquipedia
-- wiki=commons
-- page=Module:ThisDay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local ThisDayBirthday = Lua.import('Module:Widget/ThisDay/Birthday')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ThisDayConfig
---@field hideEmptyBirthdayList boolean?
---@field showPatches boolean?
---@field showEmptyPatchList boolean?
---@field showTrivia boolean?
---@field tiers integer[]
---@field tierTypes string[]

local Config = Lua.import('Module:ThisDay/config', {loadData = true})

---@class ThisDayParameters
---@field date string?
---@field month integer?
---@field day integer?

local ThisDay = {}

---@param args table
---@return Widget
function ThisDay.run(args)
	local patchesList = ThisDay.patch(args)
	local tournaments = {
		HtmlWidgets.H3{children = 'Tournaments'},
		ThisDay.tournament(args)
	}
	local birthdays = ThisDay.birthday(args)
	local patches = patchesList and {
		HtmlWidgets.H3{children = 'Patches'},
		patchesList
	} or {}
	local trivia = Config.showTrivia and ThisDay.trivia(args) or nil
	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(tournaments, birthdays, patches, trivia)
	}
end

--- Get and display birthdays that happened on a given date (falls back to today)
---@param args ThisDayBirthdayParameters
---@return string|Widget?
function ThisDay.birthday(args)
	local month, day = ThisDay._readDate(args)

	return ThisDayBirthday{
		month = month,
		day = day,
		hideIfEmpty = Config.hideEmptyBirthdayList,
		noTwitter = args.noTwitter
	}
end

--- Get and display patches that happened on a given date (falls back to today)
---@param args ThisDayParameters
---@return string|Widget?
function ThisDay.patch(args)
	if not Config.showPatches then return end
	local patchData = ThisDayQuery.patch(ThisDay._readDate(args))

	if Logic.isEmpty(patchData) then
		if Config.showEmptyPatchList then return 'There were no patches on this day' end
		return
	end
	local lines = Array.map(patchData, function (patch)
		local patchYear = patch.releaseDate.year
		return {
			HtmlWidgets.B{
				children = {patchYear}
			},
			': ',
			Link{link = patch.pageName, children = patch.displayName},
			' released'
		}
	end)

	return UnorderedList{ children = lines }
end

--- Get and display tournament wins that happened on a given date (falls back to today)
---@param args ThisDayParameters
---@return string|Widget?
function ThisDay.tournament(args)
	local tournamentWinData = ThisDayQuery.tournament(ThisDay._readDate(args))

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
			ThisDay._displayWins(yearData)
		)
	end
	mw.logObject(display)
	return HtmlWidgets.Fragment{children = display}
end

--- Display win rows of a year
---@param yearData placement[]
---@return Widget?
function ThisDay._displayWins(yearData)
	local display = Array.map(yearData, function (placement)
		local displayName = placement.shortname
		if String.isEmpty(displayName) then
			displayName = placement.tournament
			if String.isEmpty(displayName) then
				displayName = string.gsub(placement.pagename, '_', ' ')
			end
		end

		local row = {
			LeagueIcon.display{
				icon = placement.icon,
				iconDark = placement.icondark,
				link = placement.pagename,
				date = placement.date,
				series = placement.series,
				name = placement.shortname,
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

--- Reads trivia from subpages of 'Liquipedia:This day'
---@param args ThisDayParameters
---@return (string|Widget)[]
function ThisDay.trivia(args)
	local month, day = ThisDay._readDate(args)
	local triviaText = Template.safeExpand(
		mw.getCurrentFrame(),
		String.interpolate('Liquipedia:This day/${month}/${day}', {month = month, day = day})
	)
	return String.isNotEmpty(triviaText) and {
		HtmlWidgets.H3{children = 'Trivia'},
		triviaText
	} or {}
end

--- Read date/month/day input
---@param args ThisDayParameters
---@return integer
---@return integer
function ThisDay._readDate(args)
	local date = Logic.emptyOr(args.date, os.date('%Y-%m-%d')) --[[@as string]]
	local dateArray = mw.text.split(date, '-', true)

	return tonumber(args.month or dateArray[#dateArray - 1]) --[[@as integer]],
		tonumber(args.day or dateArray[#dateArray]) --[[@as integer]]
end

return Class.export(ThisDay)
