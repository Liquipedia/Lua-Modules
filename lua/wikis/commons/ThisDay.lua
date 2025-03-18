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

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local CONFIG = Lua.import('Module:ThisDay/config', {loadData = true})

local DEFAULT_CONFIG = {
	tiers = {1, 2},
	tierTypes = {'!Qualifier'},
	tierTypeBooleanOperator = BooleanOperator.any,
	soloMode = '', -- legacy!
}

local Query = {}

--- Queries birthday data
---@param month integer
---@param day integer
---@return table?
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
---@return table?
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
---@return table?
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
		CONFIG.tiers or DEFAULT_CONFIG.tiers,
		BooleanOperator.any
	))
	conditions:add(Query._multiValueCondition(
		'liquipediatiertype',
		CONFIG.tierTypes or DEFAULT_CONFIG.tierTypes, CONFIG.tierTypeBooleanOperator or DEFAULT_CONFIG.tierTypeBooleanOperator
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
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string
function ThisDay.birthday(args)
	local birthdayData = Query.birthday(ThisDay._readDate(args))

	if not birthdayData then
		return 'There are no birthdays today'
	else
		local nowArray = mw.text.split(os.date('%Y-%m-%d'), '-', true)
		local lines = {}
		for _, player in ipairs(birthdayData) do
			local birthdateArray = mw.text.split(player.birthdate, '-', true)
			local birthYear = birthdateArray[1]
			local age = tonumber(nowArray[1]) - tonumber(birthdateArray[1])
			if
				birthdateArray[2] > nowArray[2] or (
					birthdateArray[2] == nowArray[2]
					and birthdateArray[3] > nowArray[3]
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
			local line = '* ' .. tostring(OpponentDisplay.InlineOpponent{
				opponent = {players = {playerData}, type = Opponent.solo}
			}) .. ' - ' .. birthYear .. ' (age ' .. age .. ')'

			if String.isNotEmpty((player.links or {}).twitter) and not Logic.readBool(args.noTwitter) then
				line = line .. ' <i class="lp-icon lp-icon-25 lp-twitter share-birthday" data-url="'
					.. player.links.twitter .. '" data-page="' .. player.pagename
					.. '" title="Send a message to ' .. player.id
					.. ' about their birthday!" style="cursor:pointer;"></i>'
			end

			table.insert(lines, line)
		end

		return table.concat(lines, '\n')
	end
end

--- Get and display patches that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string
function ThisDay.patch(args)
	local patchData = Query.patch(ThisDay._readDate(args))

	if not patchData then
		return 'There were no patches on this day'
	else
		local lines = {}

		for _, patch in ipairs(patchData) do
			local patchYear = patch.date:sub(1, 4)
			table.insert(lines, '* <b>' .. patchYear .. '</b>: [[' .. patch.pagename .. ' |' .. patch.name .. ']] released')
		end

		return table.concat(lines, '\n')
	end
end

--- Get and display tournament wins that happened on a given date (falls back to today)
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return string
function ThisDay.tournament(args)
	local tournamentWinData = Query.tournament(ThisDay._readDate(args))

	if not tournamentWinData then
		return 'No tournament ended on this date'
	else
		local byYear
		_, byYear = Array.groupBy(tournamentWinData, function(placement) return placement.date:sub(1, 4) end)

		local display = {}
		for year, yearData in Table.iter.spairs(byYear) do
			table.insert(display, '====' .. year .. '====')
			table.insert(display, ThisDay._displayWins(yearData))
		end

		return table.concat(display, '\n')
	end
end

--- Display win rows of a year
---@param yearData table
---@return string
function ThisDay._displayWins(yearData)
	local display = {}
	for _, placement in ipairs(yearData) do
		local displayName = placement.shortname
		if String.isEmpty(displayName) then
			displayName = placement.tournament
			if String.isEmpty(displayName) then
				displayName = string.gsub(placement.pagename, '_', ' ')
			end
		end

		local row = '* ' .. LeagueIcon.display{
			icon = placement.icon,
			iconDark = placement.icondark,
			link = placement.pagename,
			date = placement.date,
			series = placement.series,
			name = placement.shortname,
		} .. ' [[' .. placement.pagename .. '|' .. displayName .. ']] won by '

		local opponent
		if placement.opponenttype then
			opponent = Opponent.fromLpdbStruct(placement)

		-- legacy opponent building
		elseif placement.mode == CONFIG.soloMode then
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
		table.insert(display, row .. tostring(OpponentDisplay.InlineOpponent{opponent = opponent}))
	end

	return table.concat(display, '\n')
end

--- Read date/month/day input
---@param args {date: string?, month: string|integer|nil, day: string|integer|nil}
---@return integer|string
function ThisDay._readDate(args)
	local date = String.isNotEmpty(args.date) and args.date or os.date('%Y-%m-%d')
	local dateArray = mw.text.split(date, '-', true)

	return tonumber(args.month) or dateArray[#dateArray - 1], tonumber(args.day) or dateArray[#dateArray]
end


return Class.export(ThisDay)
