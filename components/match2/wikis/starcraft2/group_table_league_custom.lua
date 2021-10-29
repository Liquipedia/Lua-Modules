---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:GroupTableLeague/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TeamTemplates = require('Module:TeamTemplates')
local Player = require('Module:Player')
local String = require('Module:String')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local BigRaceIcon = require('Module:RaceIcon')._getBigIcon
--local GroupTableLeague = require('Module:GroupTableLeague')
local GroupTableLeague = require('Module:Hjpalpha/sandbox19')

local CustomGroupTableLeague = {
	display = {},
	parseOpponentInput = {}
}

local _storageNames = {}

function CustomGroupTableLeague.create(args)

	GroupTableLeague.display.solo = CustomGroupTableLeague.display.solo
	GroupTableLeague.display.team = CustomGroupTableLeague.display.team
	GroupTableLeague.display.duo = CustomGroupTableLeague.display.duo
	GroupTableLeague.display.trio = CustomGroupTableLeague.display.trio
	GroupTableLeague.display.quad = CustomGroupTableLeague.display.quad
	GroupTableLeague.display.archon = CustomGroupTableLeague.display.archon
	GroupTableLeague.display.other = CustomGroupTableLeague.display.other

	GroupTableLeague.parseOpponentInput.solo = CustomGroupTableLeague.parseOpponentInput.solo
	GroupTableLeague.parseOpponentInput.team = CustomGroupTableLeague.parseOpponentInput.team
	GroupTableLeague.parseOpponentInput.duo = CustomGroupTableLeague.parseOpponentInput.duo
	GroupTableLeague.parseOpponentInput.trio = CustomGroupTableLeague.parseOpponentInput.trio
	GroupTableLeague.parseOpponentInput.quad = CustomGroupTableLeague.parseOpponentInput.quad
	GroupTableLeague.parseOpponentInput.archon = CustomGroupTableLeague.parseOpponentInput.archon
	GroupTableLeague.parseOpponentInput.other = CustomGroupTableLeague.parseOpponentInput.other

	GroupTableLeague.convertType = CustomGroupTableLeague.convertType
	GroupTableLeague.lpdbConditions = CustomGroupTableLeague.lpdbConditions

	return GroupTableLeague.create(args)
end

--functions to get the display
function CustomGroupTableLeague.display.solo(opp)
	return Player._player({
		opp.opponentArg or opp.opponent,
		link = opp.opponent,
		flag = opp.flag,
		race = opp.race,
		novar = 'true'
	})
end

function CustomGroupTableLeague.display.team(opp, date)
	return TeamTemplates._team(opp.opponent, date)
end

function CustomGroupTableLeague.display.other(opp, numberOfPlayers)
	local output = {}
	for i = 1, numberOfPlayers do
		table.insert(output, Player._player({
			opp['opponent' .. i .. 'Arg'] or opp['opponent' .. i],
			link = opp['opponent' .. i],
			flag = opp['flag' .. i],
			race = opp['race' .. i],
			novar = 'true'
		}))
	end
	return table.concat(output, '<br>')
end

function CustomGroupTableLeague.display.archon(opp)
	local player1 = {
		opp.opponent1Arg or opp.opponent1,
		link = opp.opponent1,
		flag = opp.flag1,
		novar = 'true'
	}
	local player2 = {
		opp.opponent2Arg or opp.opponent2,
		link = opp.opponent2,
		flag = opp.flag2,
		novar = 'true'
	}
	local output = mw.html.create('table'):css('text-align', 'left')
		:tag('tr'):addClass('archon-table-bg')
			:tag('td')
				:css('border', '0px')
				:css('padding', '0px')
				:css('width', '35px')
				:attr('rowspan', '2')
				:wikitext(' ' .. BigRaceIcon({opp.race})):done()
			:tag('td')
				:css('border', '0px')
				:css('padding', '0px')
				:wikitext(Player._player(player1)):done():done()
		:tag('tr'):addClass('archon-table-bg')
			:tag('td')
				:css('border', '0px')
				:css('padding', '0px')
				:wikitext(Player._player(player2)):done():done():done()
	return tostring(output)
end

function CustomGroupTableLeague.display.duo(opp)
	return CustomGroupTableLeague.display.other(opp, 2)
end

function CustomGroupTableLeague.display.trio(opp)
	return CustomGroupTableLeague.display.other(opp, 3)
end

function CustomGroupTableLeague.display.quad(opp)
	return CustomGroupTableLeague.display.other(opp, 4)
end

--functions to parse opponent input
function CustomGroupTableLeague.parseOpponentInput.solo(param, opponentIndex, opponentArg, args, opponents)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args[param .. opponentIndex .. 'link'] or
		Variables.varDefault(opponentArg .. '_page', opponentArg)
	)

	local opponentListEntry = {
		opponent = opponent,
		opponentArg = opponentArg,
		flag = args[param .. opponentIndex .. 'flag'] or Variables.varDefault(opponentArg .. '_flag', ''),
		race = args[param .. opponentIndex .. 'race'] or Variables.varDefault(opponentArg .. '_race', ''),
		note = args[param .. opponentIndex .. 'note'] or args[param .. opponentIndex .. 'note'] or '',
	}

	opponents[#opponents + 1] = opponent

	local aliasList = mw.text.split(args[param .. opponentIndex .. 'alias'] or '', ',')

	return opponentListEntry, aliasList, opponents
end

function CustomGroupTableLeague.parseOpponentInput.team(param, opponentIndex, opponentArg, args, opponents)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		TeamTemplates._teampage((opponentArg or '') ~= '' and opponentArg or 'tbd')
	)

	local opponentListEntry = {
		opponent = opponent,
		opponentArg = opponentArg,
	}

	opponents[#opponents + 1] = opponent

	local aliasList = mw.text.split(args[param .. opponentIndex .. 'alias'] or '', ',')

	return opponentListEntry, aliasList, opponents
end

function CustomGroupTableLeague.parseOpponentInput.duo(param, opponentIndex, opponentArg, args, opponents)
	return CustomGroupTableLeague.parseOpponentInput.other(param, opponentIndex, opponentArg, args, opponents, 2)
end

function CustomGroupTableLeague.parseOpponentInput.trio(param, opponentIndex, opponentArg, args, opponents)
	return CustomGroupTableLeague.parseOpponentInput.other(param, opponentIndex, opponentArg, args, opponents, 3)
end

function CustomGroupTableLeague.parseOpponentInput.quad(param, opponentIndex, opponentArg, args, opponents)
	return CustomGroupTableLeague.parseOpponentInput.other(param, opponentIndex, opponentArg, args, opponents, 4)
end

function CustomGroupTableLeague.parseOpponentInput.other(param, opponentIndex, opponentArg, args, opponents, numberOfPlayers)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args[param .. opponentIndex .. 'p1link'] or
		Variables.varDefault(opponentArg .. '_page', opponentArg)
	)
	local opponentListEntry = {
		opponent1 = opponent,
		opponent1Arg = opponentArg,
		flag1 = args[param .. opponentIndex .. 'p1flag'] or Variables.varDefault(opponentArg .. '_flag', ''),
		race1 = args[param .. opponentIndex .. 'p1race'] or Variables.varDefault(opponentArg .. '_race', ''),
		note = args[param .. opponentIndex .. 'note'] or args[param .. opponentIndex .. 'note'] or '',
	}

	for i = 2, numberOfPlayers do
		opponentArg = args[param .. opponentIndex .. 'p' .. i]
		opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
			args[param .. opponentIndex .. 'p' .. i .. 'link'] or
			Variables.varDefault(opponentArg .. '_page', opponentArg)
		)
		opponentListEntry['opponent' .. i] = opponent
		opponentListEntry['opponent' .. i .. 'Arg'] = opponentArg
		opponentListEntry['flag' .. i] = args[param .. opponentIndex .. 'p' .. i .. 'flag']
			or Variables.varDefault(opponentArg .. '_flag', '')
		opponentListEntry['race' .. i] = args[param .. opponentIndex .. 'p' .. i .. 'race']
			or Variables.varDefault(opponentArg .. '_race', '')
	end

	CustomGroupTableLeague._getStorageNames(opponentListEntry, numberOfPlayers)

	local aliasList = mw.text.split(args[param .. opponentIndex .. 'alias'] or '', ',')
	for _, item in pairs(_storageNames) do
		table.insert(aliasList, item)
		table.insert(opponents, item)
	end
	opponentListEntry.opponent = _storageNames[1]
	_storageNames = {}

	return opponentListEntry, aliasList, opponents
end

function CustomGroupTableLeague.parseOpponentInput.archon(param, opponentIndex, opponentArg, args, opponents)
	local opponent = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args[param .. opponentIndex .. 'p1link'] or
		Variables.varDefault(opponentArg .. '_page', opponentArg)
	)
	local opponent2Arg = args[param .. opponentIndex .. 'p2']
	local opponent2 = mw.ext.TeamLiquidIntegration.resolve_redirect(
		args[param .. opponentIndex .. 'p2link'] or
		Variables.varDefault(opponent2Arg .. '_page', opponent2Arg)
	)
	local opponentListEntry = {
		opponent1 = opponent,
		opponent1Arg = opponentArg,
		flag1 = args[param .. opponentIndex .. 'p1flag'] or Variables.varDefault(opponentArg .. '_flag', ''),
		opponent2 = opponent2,
		opponent2Arg = opponent2Arg,
		flag2 = args[param .. opponentIndex .. 'p2flag'] or Variables.varDefault(opponent2Arg .. '_flag', ''),
		race = args[param .. opponentIndex .. 'race'] or '',
		note = args[param .. opponentIndex .. 'note'] or args[param .. opponentIndex .. 'note'] or '',
	}

	CustomGroupTableLeague._getStorageNames(opponentListEntry, 2)

	local aliasList = mw.text.split(args[param .. opponentIndex .. 'alias'] or '', ',')
	for _, item in pairs(_storageNames) do
		table.insert(aliasList, item)
		table.insert(opponents, item)
	end
	opponentListEntry.opponent = _storageNames[1]
	_storageNames = {}

	return opponentListEntry, aliasList, opponents
end

function CustomGroupTableLeague._getStorageNames(opponentListEntry, numberOfPlayers)
	local opponents = {}
	for i = 1, numberOfPlayers do
		table.insert(opponents, opponentListEntry['opponent' .. i])
	end

	CustomGroupTableLeague._permutation(opponents, numberOfPlayers, CustomGroupTableLeague._permutationCallback)
end

function CustomGroupTableLeague._permutation(array, numberOfElements)
	if numberOfElements == 0 then
		CustomGroupTableLeague._permutationCallback(array)
	else
		for i = 1, numberOfElements do
			array[i], array[numberOfElements] = array[numberOfElements], array[i]
			CustomGroupTableLeague._permutation(array, numberOfElements - 1)
			array[i], array[numberOfElements] = array[numberOfElements], array[i]
		end
	end
end

function CustomGroupTableLeague._permutationCallback(array)
	table.insert(_storageNames, table.concat(array or {}, ' / '))
end

--function to determine the following from args.type
----tableType (determines the display of the opponents)
----mode (used in the lpdb query conditions)
local _DEFAULT_TYPE = 'solo'
local _TYPE_TO_MODE = {
	['solo'] = '1_1',
	['duo'] = '2_2',
	['archon'] = 'Archon_Archon',
	['trio'] = '3_3',
	['quad'] = '4_4',
	['team'] = 'team_team',
}
local _ALLOWED_TYPES = {
	['solo'] = 'solo',
	['duo'] = 'duo',
	['archon'] = 'archon',
	['trio'] = 'trio',
	['quad'] = 'quad',
	['team'] = 'team',
}
local _TYPE_TO_PARAMS = {
	['solo'] = {'player', 'p'},
	['duo'] = {'duo'},
	['archon'] = {'archon'},
	['trio'] = {'trio'},
	['quad'] = {'quad'},
	['team'] = {'team', 't'},
}
function CustomGroupTableLeague.convertType(tableType)
	tableType = _ALLOWED_TYPES[string.lower(tableType or _DEFAULT_TYPE)] or _DEFAULT_TYPE
	return tableType, _TYPE_TO_MODE[tableType], _TYPE_TO_PARAMS[tableType]
end

function CustomGroupTableLeague.lpdbConditions(args, opponents, mode, baseConditions, dateConditions)
	baseConditions = baseConditions .. ' AND [[mode::' .. mode .. ']]'
	local lpdbConditions = baseConditions

	local oppConditions = ''
	if type(opponents) == 'table' and opponents[1] then
		local oppNumber = #opponents
		oppConditions = oppConditions .. 'AND ('
		for key = 1, oppNumber - 1 do
			for key2 = key + 1, oppNumber do
				if key > 1 or key2 > 2 then
					oppConditions = oppConditions .. ' OR '
				end
				oppConditions = oppConditions ..
					'[[opponent::' .. opponents[key] .. ']] AND [[opponent::' .. opponents[key2] .. ']]'
			end
		end
		oppConditions = oppConditions .. ') '
	end

	if not String.isEmpty(dateConditions) then
		lpdbConditions = lpdbConditions .. ' AND ' .. dateConditions
	end

	if not String.isEmpty(oppConditions) then
		lpdbConditions = lpdbConditions .. oppConditions
	end

	return lpdbConditions, baseConditions
end

return Class.export(CustomGroupTableLeague)
