---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/ConvertMapData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local TBD = 'TBD'
local NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_SUBMATCHES_IN_MULTI = 9
local DEFAULT_WIN = 'W'
local WALKOVER_INPUT_TO_SCORE_INPUT = {
	w = DEFAULT_WIN,
	skip = 'L',
	l = 'L',
	dq = 'DQ',
	ff = 'FF',
}

local ConvertMapData = {}

---@param args table?
---@return string
function ConvertMapData.solo(args)
	args = args or {}
	--sometimes win param is entered differently ...
	for _, value, index in Table.iter.pairsByPrefix(args, 'win') do
		args['map' .. index .. 'win'] = value
		args['map' .. index] = args['map' .. index] or TBD
	end

	return Json.stringify(args)
end

--structure formerly used by `Template:BracketTeamMatch`
---@param args table?
---@return string
function ConvertMapData.team(args)
	args = args or {}

	local parsedArgs = Table.filterByKey(args, function(key)
		return string.match(key, 'm%d') == nil
	end)

	local opponentPlayers = {{}, {}}
	local mapIndex = 1
	local prefix = 'm' .. mapIndex
	while args[prefix .. 'p1'] or args[prefix .. 'p2'] or args[prefix .. 'map'] do
		local parsedPrefix = 'map' .. mapIndex
		parsedArgs[parsedPrefix] = args[prefix .. 'map'] or TBD
		parsedArgs[parsedPrefix .. 'win'] = args[prefix .. 'win']

		for opponentIndex = 1, NUMBER_OF_OPPONENTS do
			local playerInputPrefix = prefix .. 'p' .. opponentIndex
			local playerPrefix = parsedPrefix .. 't' .. opponentIndex .. 'p1'

			local name = args[playerInputPrefix .. 'link'] or args[playerInputPrefix] or TBD
			local player = {
				name = name,
				displayname = args[playerInputPrefix] or name,
				flag = args[playerInputPrefix .. 'flag'],
				race = args[playerInputPrefix .. 'race'],
			}
			opponentPlayers[opponentIndex][name] = player

			parsedArgs[playerPrefix] = name
			parsedArgs[playerPrefix .. 'race'] = player.race
			parsedArgs[playerPrefix .. 'heroes'] = args[playerInputPrefix .. 'heroes']
		end

		mapIndex = mapIndex + 1
		prefix = 'm' .. mapIndex
	end

	Array.forEach(opponentPlayers, function(players, opponentIndex)
		Array.forEach(Array.extractValues(players), function(player, playerIndex)
			parsedArgs['opponent' .. opponentIndex .. '_p' .. playerIndex] = Json.stringify(player)
		end)
	end)

	return Json.stringify(parsedArgs)
end

--structure formerly used by `Template:BracketTeamMatchMulti`
---@param args table?
---@return string
function ConvertMapData.teamMulti(args)
	args = args or {}

	local parsedArgs = Table.filterByKey(args, function(key)
		return string.match(key, 'm%d') == nil
	end)

	local opponentPlayers = {{}, {}}
	local submatchIndex = 0
	local mapIndex = 0

	--the old template allowed missing submatches inbetween, hence need to loop like this
	Array.forEach(Array.range(1, MAX_NUMBER_OF_SUBMATCHES_IN_MULTI), function(prefixIndex)
		local prefix = 'm' .. prefixIndex
		if args[prefix .. 'p1'] or args[prefix .. 'p2'] or args[prefix .. 'map1'] then
			submatchIndex = submatchIndex + 1
			mapIndex = ConvertMapData._convertSubmatch(opponentPlayers, parsedArgs, args, prefix, submatchIndex, mapIndex)
		end
	end)

	Array.forEach(opponentPlayers, function(players, opponentIndex)
		Array.forEach(Array.extractValues(players), function(player, playerIndex)
			parsedArgs['opponent' .. opponentIndex .. '_p' .. playerIndex] = Json.stringify(player)
		end)
	end)

	return Json.stringify(parsedArgs)
end

function ConvertMapData._convertSubmatch(opponentPlayers, parsedArgs, args, prefix, submatchIndex, mapIndex)
	local playersArrays = {{}, {}}

	Array.forEach(Array.range(1, NUMBER_OF_OPPONENTS), function(opponentIndex)
		ConvertMapData._readSubmatchPlayers(args, playersArrays, opponentPlayers, prefix, opponentIndex)
	end)

	local hasMissingWinner = false
	local submatchScores = {0, 0}
	for mapPrefix, map, submatchMapIndex in Table.iter.pairsByPrefix(args, prefix .. 'map') do
		mapIndex = mapIndex + 1
		local parsedPrefix = 'map' .. mapIndex
		parsedArgs[parsedPrefix] = map
		parsedArgs[parsedPrefix .. 'subgroup'] = submatchIndex
		parsedArgs[parsedPrefix .. 'finished'] = true

		local winner = tonumber(args[prefix .. 'win' .. submatchMapIndex])
		parsedArgs[parsedPrefix .. 'win'] = winner
		if winner and submatchScores[winner] then
			submatchScores[winner] = submatchScores[winner] + 1
		elseif winner ~= 0 then
			hasMissingWinner = true
		end

		Array.forEach(playersArrays, function(players, opponentIndex)
			Array.forEach(players, function(player, playerIndex)
				parsedArgs[parsedPrefix .. 't' .. opponentIndex .. 'p' .. playerIndex] = player.name
			end)
			--only had race and heroes support for 1v1 submatches ...
			local playerPrefix = parsedPrefix .. 't' .. opponentIndex .. 'p1'
			parsedArgs[playerPrefix .. 'race'] = args[mapPrefix .. 'p' .. opponentIndex .. 'race'] or players[1].race
			parsedArgs[playerPrefix .. 'heroes'] = args[mapPrefix .. 'p' .. opponentIndex .. 'heroes']
		end)
	end

	local score1 = ConvertMapData._readSubmatchScore(args, prefix, submatchScores, 1)
	local score2 = ConvertMapData._readSubmatchScore(args, prefix, submatchScores, 2)
	local submatchIsNotDefaultWin = Logic.isNumeric(score1) and Logic.isNumeric(score2)

	if submatchIsNotDefaultWin and not hasMissingWinner then
		return mapIndex
	end

	mapIndex = mapIndex + 1
	local parsedPrefix = 'map' .. mapIndex
	parsedArgs[parsedPrefix .. 'subgroup'] = submatchIndex
	parsedArgs[parsedPrefix .. 'p1score'] = score1
	parsedArgs[parsedPrefix .. 'p2score'] = score2
	parsedArgs[parsedPrefix] = submatchIsNotDefaultWin and 'Submatch Score Fix' or 'Submatch'
	parsedArgs[parsedPrefix .. 'finished'] = true

	Array.forEach(playersArrays, function(players, opponentIndex)
		Array.forEach(players, function(player, playerIndex)
			parsedArgs[parsedPrefix .. 't' .. opponentIndex .. 'p' .. playerIndex] = player.name
		end)
	end)

	return mapIndex
end

function ConvertMapData._readSubmatchScore(args, prefix, submatchScores, opponentIndex)
	local scoreInput = args[prefix .. 'p' .. opponentIndex .. 'score']

	return WALKOVER_INPUT_TO_SCORE_INPUT[(scoreInput or ''):lower()]
		or ((tonumber(scoreInput) or 0) - submatchScores[opponentIndex])
end

function ConvertMapData._readSubmatchPlayers(args, players, opponentPlayers, prefix, opponentIndex)
	local playerInputPrefix = prefix .. 'p' .. opponentIndex
	local name = args[playerInputPrefix .. 'link'] or args[playerInputPrefix] or TBD
	opponentPlayers[opponentIndex][name] = {
		name = name,
		displayname = args[playerInputPrefix] or name,
		flag = args[playerInputPrefix .. 'flag'],
		race = args[playerInputPrefix .. 'race'],
	}
	table.insert(players[opponentIndex], Table.copy(opponentPlayers[opponentIndex][name] or {}))

	--optional second player
	local player2InputPrefix = prefix .. 'p' .. opponentIndex .. '-2'
	local name2 = args[player2InputPrefix .. 'link'] or args[player2InputPrefix]
	if not name2 then return end

	opponentPlayers[opponentIndex][name2] = {
		name = name2,
		displayname = args[player2InputPrefix] or name2,
		flag = args[player2InputPrefix .. 'flag'],
		race = args[player2InputPrefix .. 'race'],
	}
	table.insert(players[opponentIndex], Table.copy(opponentPlayers[opponentIndex][name2] or {}))
end

return Class.export(ConvertMapData, {exports = {'solo', 'team', 'teamMulti'}})
