---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchGroup/Legacy/ConvertMapData
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Table = require('Module:Table')

local TBD = 'TBD'
local NUMBER_OF_OPPONENTS = 2

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
	local mapIndex = 0
	local submatchIndex = 1
	local prefix = 'm' .. submatchIndex

	while args[prefix .. 'p1'] or args[prefix .. 'p2'] or args[prefix .. 'map1'] do
		--parse players
		local mapPlayers = {{}, {}}
		for opponentIndex = 1, NUMBER_OF_OPPONENTS do
			local playerInputPrefix = prefix .. 'p' .. opponentIndex

			local name = args[playerInputPrefix .. 'link'] or args[playerInputPrefix] or TBD
			opponentPlayers[opponentIndex][name] = {
				name = name,
				displayname = args[playerInputPrefix] or name,
				flag = args[playerInputPrefix .. 'flag'],
				race = args[playerInputPrefix .. 'race'],
			}
			table.insert(mapPlayers, opponentPlayers[opponentIndex][name])

			--optional second player
			local player2InputPrefix = prefix .. 'p' .. opponentIndex .. '-2'
			local name2 = args[player2InputPrefix .. 'link'] or args[player2InputPrefix]
			if name2 then
				opponentPlayers[opponentIndex][name2] = {
					name = name2,
					displayname = args[player2InputPrefix] or name,
					flag = args[player2InputPrefix .. 'flag'],
					race = args[player2InputPrefix .. 'race'],
				}
			end
			table.insert(mapPlayers, opponentPlayers[opponentIndex][name2])
		end

		for mapPrefix, map, submatchMapIndex in Table.iter.pairsByPrefix(args, prefix .. 'map') do
			mapIndex = mapIndex + 1
			local parsedPrefix = 'map' .. mapIndex
			parsedArgs[parsedPrefix] = map
			parsedArgs[parsedPrefix .. 'subgroup'] = submatchIndex
			parsedArgs[parsedPrefix .. 'win'] = args[prefix .. 'win' .. submatchMapIndex]

			Array.forEach(mapPlayers, function(players, opponentIndex)
				Array.forEach(players, function(player, playerIndex)
					local playerPrefix = parsedPrefix .. 't' .. opponentIndex .. 'p' .. playerIndex
					parsedArgs[playerPrefix] = player.name
				end)
				--only had race and heroes support for 1v1 submatches ...
				local playerPrefix = parsedPrefix .. 't' .. opponentIndex .. 'p1'
				parsedArgs[playerPrefix .. 'race'] = args[mapPrefix .. 'p' .. opponentIndex .. 'race']
				parsedArgs[playerPrefix .. 'heroes'] = args[mapPrefix .. 'p' .. opponentIndex .. 'heroes']
			end)
		end

		submatchIndex = submatchIndex + 1
		prefix = 'm' .. submatchIndex
	end

	Array.forEach(opponentPlayers, function(players, opponentIndex)
		Array.forEach(Array.extractValues(players), function(player, playerIndex)
			parsedArgs['opponent' .. opponentIndex .. '_p' .. playerIndex] = Json.stringify(player)
		end)
	end)

	return Json.stringify(parsedArgs)
end

return Class.export(ConvertMapData)
