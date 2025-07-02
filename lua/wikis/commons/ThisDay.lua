---
-- @Liquipedia
-- page=Module:ThisDay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ThisDayBirthday = Lua.import('Module:Widget/ThisDay/Birthday')
local ThisDayPatch = Lua.import('Module:Widget/ThisDay/Patch')
local ThisDayTournament = Lua.import('Module:Widget/ThisDay/Tournament')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ThisDayConfig
---@field hideEmptyBirthdayList boolean?
---@field showPatches boolean?
---@field showEmptyPatchList boolean?
---@field showTrivia boolean?
---@field tiers integer[]
---@field excludeTierTypes string[]

---@type ThisDayConfig
local Config = Info.config.thisDay or {}

---@class ThisDayParameters
---@field date string?
---@field month integer?
---@field day integer?

local ThisDay = {}

---@param args table
---@return Widget
function ThisDay.run(args)
	local tournaments = ThisDay.tournament(args)
	local birthdays = ThisDay.birthday(args)
	local patches = ThisDay.patch(args)
	local trivia = Logic.readBool(Config.showTrivia) and ThisDay.trivia(args) or nil
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
		hideIfEmpty = Logic.readBool(Config.hideEmptyBirthdayList),
		noTwitter = args.noTwitter
	}
end

--- Get and display patches that happened on a given date (falls back to today)
---@param args ThisDayParameters
---@return Widget?
function ThisDay.patch(args)
	if not Logic.readBool(Config.showPatches) then return end
	local month, day = ThisDay._readDate(args)

	return ThisDayPatch{
		month = month,
		day = day,
		hideIfEmpty = not Logic.readBool(Config.showEmptyPatchList)
	}
end

--- Get and display tournament wins that happened on a given date (falls back to today)
---@param args ThisDayParameters
---@return string|Widget?
function ThisDay.tournament(args)
	local month, day = ThisDay._readDate(args)

	return ThisDayTournament{
		month = month,
		day = day
	}
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
