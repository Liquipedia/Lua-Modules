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
local Flags = require('Module:Flags')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_CONFIG = {
	tiers = {1, 2},
	tierTypes = {'!Qualifier'},
	tierTypeBooleanOperator = BooleanOperator.any,
	soloMode = '', -- legacy!
}

local Config = Table.merge(DEFAULT_CONFIG, Lua.import('Module:ThisDay/config', {loadData = true}))

local Query = {}

--- Queries birthday data
---@param month integer
---@param day integer
---@return player[]?
function Query.birthday(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('birthdate_month'), Comparator.eq, month),
			ConditionNode(ColumnName('birthdate_day'), Comparator.eq, day),
			ConditionNode(ColumnName('deathdate'), Comparator.eq, DateExt.defaultDate),
			ConditionNode(ColumnName('birthdate'), Comparator.neq, DateExt.defaultDate),
		}

	local birthdayData = mw.ext.LiquipediaDB.lpdb('player', {
		limit = 5000,
		conditions = conditions:toString(),
		query = 'extradata, pagename, id, birthdate, nationality, links',
		order = 'birthdate asc, id asc'
	})

	if type(birthdayData[1]) == 'table' then
		return birthdayData
	end
end

--- Queries patch data
---@param month integer
---@param day integer
---@return datapoint?
function Query.patch(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
			ConditionNode(ColumnName('date_month'), Comparator.eq, month),
			ConditionNode(ColumnName('date_day'), Comparator.eq, day),
			ConditionNode(ColumnName('type'), Comparator.eq, 'patch'),
		}

	local patchData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 5000,
		conditions = conditions:toString(),
		query = 'pagename, name, date',
		order = 'date asc, name asc'
	})

	if type(patchData[1]) == 'table' then
		return patchData
	end
end

--- Queries tournament win data
---@param month integer
---@param day integer
---@return placement[]?
function Query.tournament(month, day)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate),
			ConditionNode(ColumnName('date_month'), Comparator.eq, month),
			ConditionNode(ColumnName('date_day'), Comparator.eq, day),
			ConditionNode(ColumnName('date'), Comparator.lt, os.date('%Y-%m-%d', os.time() - 86400)),
			ConditionNode(ColumnName('placement'), Comparator.eq, 1),
			ConditionNode(ColumnName('opponentname'), Comparator.neq, 'TBD'),
			ConditionNode(ColumnName('opponentname'), Comparator.neq, 'Definitions'),
			ConditionTree(BooleanOperator.any)
				:add{ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, '')}
				:add{ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, '1')}
		}
	conditions:add(Query._multiValueCondition(
		'liquipediatier',
		Config.tiers,
		BooleanOperator.any
	))
	conditions:add(Query._multiValueCondition(
		'liquipediatiertype',
		Config.tierTypes,
		Config.tierTypeBooleanOperator
	))

	local tournamentWinData = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = conditions:toString(),
		query = 'extradata, pagename, date, icon, icondark, shortname, tournament, series, '
			.. 'opponentname, opponenttemplate, opponentplayers, opponenttype'
			.. ', mode, participant, participantflag, participanttemplate', --this line for legacy reasons
		order = 'date asc, pagename asc'
	})

	if type(tournamentWinData[1]) == 'table' then
		return tournamentWinData
	end
end

--- build conditions for multi variable
---@param key string
---@param values table
---@param booleanOperator lpdbBooleanOperator
---@return table?
function Query._multiValueCondition(key, values, booleanOperator)
	if Table.isEmpty(values) then
		return
	end

	local conditions = ConditionTree(booleanOperator)

	for _, value in pairs(values) do
		conditions:add{ConditionNode(ColumnName(key), Comparator.eq, value)}
	end

	return conditions
end


local ThisDay = {}

--- Get and display birthdays that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil, noTwitter: boolean?}
---@return string|Widget?
function ThisDay.birthday(args)
	local birthdayData = Query.birthday(ThisDay._readDate(args))

	if not birthdayData then
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

		return ThisDay._buildListWidget(lines)
	end
end

--- Get and display patches that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string|Widget?
function ThisDay.patch(args)
	local patchData = Query.patch(ThisDay._readDate(args))

	if not patchData then
		return 'There were no patches on this day'
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

		return ThisDay._buildListWidget(lines)
	end
end

--- Get and display tournament wins that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string|Widget?
function ThisDay.tournament(args)
	local tournamentWinData = Query.tournament(ThisDay._readDate(args))

	if not tournamentWinData then
		return 'No tournament ended on this date'
	else
		local byYear
		_, byYear = Array.groupBy(tournamentWinData, function(placement) return placement.date:sub(1, 4) end)

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

		local opponent
		if placement.opponenttype then
			opponent = Opponent.fromLpdbStruct(placement)

		-- legacy opponent building
		elseif placement.mode == Config.soloMode then
			opponent = {
				type = Opponent.solo,
				players = {
					displayName = placement.extradata.participantname or placement.participant,
					flag = Flags.CountryName(placement.participantflag),
					pageName = placement.participant,
				},
			}
		else
			opponent = {
				type = Opponent.team,
				name = placement.participant,
				template = placement.participanttemplate or placement.participant:lower():gsub('_', ' '),
			}
		end

		if not opponent then
			mw.logObject(placement)
		end
		return Array.append(row, OpponentDisplay.InlineOpponent{opponent = opponent})
	end)

	return ThisDay._buildListWidget(display)
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

--- Build list widget from an array of elements
---@param arr ((string|Html|Widget|nil)|((string|Html|Widget|nil)[]))[]
---@return Widget?
function ThisDay._buildListWidget(arr)
	if Logic.isEmpty(arr) then return end
	return HtmlWidgets.Ul{
		children = Array.map(arr, function (element)
			return HtmlWidgets.Li{
				children = WidgetUtil.collect(element)
			}
		end)
	}
end

return Class.export(ThisDay)
