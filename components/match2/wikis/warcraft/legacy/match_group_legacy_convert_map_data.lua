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








		submatchIndex = submatchIndex + 1
		prefix = 'm' .. submatchIndex
	end



	--[[
	{{#if:{{{m1p1|}}}{{{m1p2|}}}{{{m1map1|}}}|{{BracketTeamMatchMulti/row
|p1={{{m1p1|}}}|p1flag={{{m1p1flag|}}}|p1race={{{m1p1race|}}}|p1link={{{m1p1link|}}}
|p1-2={{{m1p1-2|}}}|p1-2flag={{{m1p1-2flag|}}}|p1-2race={{{m1p1-2race|}}}|p1-2link={{{m1p1-2link|}}}
|p2={{{m1p2|}}}|p2flag={{{m1p2flag|}}}|p2race={{{m1p2race|}}}|p2link={{{m1p2link|}}}
|p2-2={{{m1p2-2|}}}|p2-2flag={{{m1p2-2flag|}}}|p2-2race={{{m1p2-2race|}}}|p2-2link={{{m1p2-2link|}}}
|p1score={{{m1p1score|0}}}|p2score={{{m1p2score|0}}}|winner={{{m1win|}}}
|map1={{{m1map1|}}}|map2={{{m1map2|}}}|map3={{{m1map3|}}}|map4={{{m1map4|}}}|map5={{{m1map5|}}}|map6={{{m1map6|}}}|map7={{{m1map7|}}}
|win1={{{m1win1}}}|win2={{{m1win2}}}|win3={{{m1win3}}}|win4={{{m1win4}}}|win5={{{m1win5}}}|win6={{{m1win6}}}|win7={{{m1win7}}}
|map1p1heroes={{{m1map1p1heroes|}}}|map2p1heroes={{{m1map2p1heroes|}}}|map3p1heroes={{{m1map3p1heroes|}}}|map4p1heroes={{{m1map4p1heroes|}}}|map5p1heroes={{{m1map5p1heroes|}}}|map6p1heroes={{{m1map6p1heroes|}}}|map7p1heroes={{{m1map7p1heroes|}}}
|map1p2heroes={{{m1map1p2heroes|}}}|map2p2heroes={{{m1map2p2heroes|}}}|map3p2heroes={{{m1map3p2heroes|}}}|map4p2heroes={{{m1map4p2heroes|}}}|map5p2heroes={{{m1map5p2heroes|}}}|map6p2heroes={{{m1map6p2heroes|}}}|map7p2heroes={{{m1map7p2heroes|}}}
|map1p1race={{{m1map1p1race|}}}|map2p1race={{{m1map2p1race|}}}|map3p1race={{{m1map3p1race|}}}|map4p1race={{{m1map4p1race|}}}|map5p1race={{{m1map5p1race|}}}|map6p1race={{{m1map6p1race|}}}|map7p1race={{{m1map7p1race|}}}
|map1p2race={{{m1map1p2race|}}}|map2p2race={{{m1map2p2race|}}}|map3p2race={{{m1map3p2race|}}}|map4p2race={{{m1map4p2race|}}}|map5p2race={{{m1map5p2race|}}}|map6p2race={{{m1map6p2race|}}}|map7p2race={{{m1map7p2race|}}}
|matchNo=1
}}}}
	]]
end

return Class.export(ConvertMapData)
