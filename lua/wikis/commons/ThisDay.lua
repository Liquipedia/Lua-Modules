---
-- @Liquipedia
-- wiki=commons
-- page=Module:ThisDay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local ThisDayQuery = Lua.import('Module:ThisDay/Query')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
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

local ThisDay = {}

---@param args table
---@return Widget
function ThisDay.run(args)
	local birthdaysList = ThisDay.birthday(args)
	local patchesList = ThisDay.patch(args)
	local tournaments = {
		HtmlWidgets.H3{children = 'Tournaments'},
		ThisDay.tournament(args)
	}
	local birthdays = birthdaysList and {
		HtmlWidgets.H3{children = 'Birthdays'},
		ThisDay.birthday(args)
	}
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
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil, noTwitter: boolean?}
---@return string|Widget?
function ThisDay.birthday(args)
	local birthdayData = ThisDayQuery.birthday(ThisDay._readDate(args))

	if Logic.isEmpty(birthdayData) then
		if Config.hideEmptyBirthdayList then return end
		return 'There are no birthdays today'
	else
		local now = DateExt.parseIsoDate(os.date('%Y-%m-%d') --[[@as string]])
		local lines = Array.map(birthdayData, function (player)
			local birthdate = DateExt.parseIsoDate(player.birthdate)
			local birthYear = birthdate.year
			local age = now.year - birthYear
			if
				birthdate.month > now.month or (
					birthdate.month == now.month
					and birthdate.day > now.day
				)
			then
				age = age - 1
			end
			local playerData = {
				displayName = player.id,
				flag = player.nationality,
				pageName = player.pagename,
				faction = (player.extradata or {}).faction,
			}
			local line = {
				OpponentDisplay.InlineOpponent{
					opponent = {players = {playerData}, type = Opponent.solo}
				},
				' - ',
				birthYear .. ' (age ' .. age .. ')'
			}

			if String.isNotEmpty((player.links or {}).twitter) and not Logic.readBool(args.noTwitter) then
				Array.appendWith(
					line,
					' ',
					HtmlWidgets.I{
						classes = {'lp-icon', 'lp-icon-25', 'lp-twitter', 'share-birthday'},
						attributes = {
							['data-url'] = player.links.twitter,
							['data-page'] = player.pagename,
							title = 'Send a message to ' .. player.id .. ' about their birthday!'
						},
						css = {cursor = 'pointer'}
					}
				)
			end

			return line
		end)

		return UnorderedList{ children = lines }
	end
end

--- Get and display patches that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string|Widget?
function ThisDay.patch(args)
	if not Config.showPatches then return end
	local patchData = ThisDayQuery.patch(ThisDay._readDate(args))

	if Logic.isEmpty(patchData) then
		return Config.showEmptyPatchList and 'There were no patches on this day' or nil
	else
		local lines = Array.map(patchData, function (patch)
			local patchYear = patch.date:sub(1, 4)
			return {
				HtmlWidgets.B{
					children = {patchYear}
				},
				': ',
				Link{link = patch.pagename, children = patch.name},
				' released'
			}
		end)

		return UnorderedList{ children = lines }
	end
end

--- Get and display tournament wins that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string|Widget?
function ThisDay.tournament(args)
	local tournamentWinData = ThisDayQuery.tournament(ThisDay._readDate(args))

	if Logic.isEmpty(tournamentWinData) then
		return 'No tournament ended on this date'
	else
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
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
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
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return integer
---@return integer
function ThisDay._readDate(args)
	local date = Logic.emptyOr(args.date, os.date('%Y-%m-%d')) --[[@as string]]
	local dateArray = mw.text.split(date, '-', true)

	return tonumber(args.month or dateArray[#dateArray - 1]) --[[@as integer]],
		tonumber(args.day or dateArray[#dateArray]) --[[@as integer]]
end

return Class.export(ThisDay)
