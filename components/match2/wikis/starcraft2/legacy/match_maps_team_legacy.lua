---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchMapsTeam/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Template = require('Module:Template')
local Json = require('Module:Json')
local Table = require('Module:Table')

local MatchMapsTeamLegacy = {}

local _storageArgs
local _args
local _opponentPlayers = {{}, {}}

local _NUMBER_OF_OPPONENTS = 2

-- invoked by Template:Match maps team
function MatchMapsTeamLegacy.preprocess(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsTeamLegacy._preProcess(args)
end

function MatchMapsTeamLegacy._preProcess(args)
	local storageArgs = Json.parse(args.details or '{}')
	_storageArgs = storageArgs

	args.details = nil
	_args = args

	MatchMapsTeamLegacy._handleMaps()

	MatchMapsTeamLegacy._handleOpponents()

	if args.date then
		args.dateheader = true
	end

	Template.stashReturnValue(Table.merge(args, storageArgs), 'LegacyMatchlist')
end

function MatchMapsTeamLegacy._handleMaps()
	local storageArgs = _storageArgs

	local gameIndex = 1
	local prefix = 'm' .. gameIndex
	local map = storageArgs[prefix .. 'map']
	local mapWinner = storageArgs[prefix .. 'win']

	while map or mapWinner do
		storageArgs['map' .. gameIndex] = MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner)

		gameIndex = gameIndex + 1
		prefix = 'm' .. gameIndex
		map = storageArgs[prefix .. 'map']
		mapWinner = storageArgs[prefix .. 'win']
	end

	prefix = 'ace'
	map = storageArgs[prefix .. 'map']
	mapWinner = storageArgs[prefix .. 'win']

	if map or mapWinner then
		storageArgs['map' .. gameIndex] = MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner)
	end
end

function MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner)
	local storageArgs = _storageArgs

	local archon = Logic.readBool(storageArgs[prefix .. 'archon'])

	local mapArgs = {
		map = map or 'unknown',
		winner = mapWinner,
	}
	mapArgs = MatchMapsTeamLegacy._processMapOpponent(1, prefix, mapArgs, archon)
	mapArgs = MatchMapsTeamLegacy._processMapOpponent(2, prefix, mapArgs, archon)

	MatchMapsTeamLegacy._removeProcessedMapInput(prefix)

	return mapArgs
end

function MatchMapsTeamLegacy._processMapOpponent(side, prefix, mapArgs, archon)
	local storageArgs = _storageArgs

	local addToMapArgs = {
		['t' .. side .. 'p1'] = String.isNotEmpty(storageArgs[prefix .. 'p' .. side .. 'link'])
			and storageArgs[prefix .. 'p' .. side .. 'link']
			or storageArgs[prefix .. 'p' .. side],
		['t' .. side .. 'p1race'] = storageArgs[prefix .. 'p' .. side .. 'race'],
		['t' .. side .. 'p1flag'] = storageArgs[prefix .. 'p' .. side .. 'flag'],

		['opponent' .. side .. 'archon'] = archon and 'true' or nil,
		['opponent' .. side .. 'race'] = archon and storageArgs[prefix .. 'p' .. side .. 'race'] or nil,

		['t' .. side .. 'p2'] = String.isNotEmpty(storageArgs[prefix .. 't' .. side .. 'p2link'])
			and storageArgs[prefix .. 't' .. side .. 'p2link']
			or storageArgs[prefix .. 't' .. side .. 'p2'],
		['t' .. side .. 'p2race'] = storageArgs[prefix .. 't' .. side .. 'p2race'],
		['t' .. side .. 'p2flag'] = storageArgs[prefix .. 't' .. side .. 'p2flag'],

		['t' .. side .. 'p3'] = String.isNotEmpty(storageArgs[prefix .. 't' .. side .. 'p3link'])
			and storageArgs[prefix .. 't' .. side .. 'p3link']
			or storageArgs[prefix .. 't' .. side .. 'p3'],
		['t' .. side .. 'p3race'] = storageArgs[prefix .. 't' .. side .. 'p3race'],
		['t' .. side .. 'p3flag'] = storageArgs[prefix .. 't' .. side .. 'p3flag'],
	}

	MatchMapsTeamLegacy._setPlayersForOpponents(addToMapArgs, side, storageArgs[prefix .. 'p' .. side])

	return Table.mergeInto(mapArgs, addToMapArgs)
end

function MatchMapsTeamLegacy._setPlayersForOpponents(args, side, displayName)
	local prefix = 't' .. side .. 'p'

	for playerKey, player in Table.iter.pairsByPrefix(args, prefix) do
		_opponentPlayers[side][player] = {
			race = args[playerKey .. 'race'],
			flag = args[playerKey .. 'flag'],
			display = displayName,
		}
	end
end

function MatchMapsTeamLegacy._removeProcessedMapInput(prefix)
	for key, _ in pairs(_storageArgs) do
		if String.startsWith(key, prefix) then
			_storageArgs[key] = nil
		end
	end
end

function MatchMapsTeamLegacy._handleOpponents()
	local storageArgs = _storageArgs
	local args = _args

	for opponentIndex = 1, _NUMBER_OF_OPPONENTS do
		if args['team' .. opponentIndex] and args['team' .. opponentIndex]:lower() == 'bye' then
			storageArgs['opponent' .. opponentIndex] = {
				['type'] = 'literal',
				name = 'BYE',
			}
		else
			storageArgs['opponent' .. opponentIndex] = {
				['type'] = 'team',
				template = args['team' .. opponentIndex],
				score = args['score' .. opponentIndex],
			}
			if args['team' .. opponentIndex] == '' then
				storageArgs['opponent' .. opponentIndex]['type'] = 'literal'
			else
				local players = {}
				local playerIndex = 1
				for player, playerData in pairs(_opponentPlayers[opponentIndex]) do
					players['p' .. playerIndex .. 'link'] = player
					players['p' .. playerIndex] = playerData.display
					players['p' .. playerIndex .. 'flag'] = playerData.flag
					players['p' .. playerIndex .. 'race'] = playerData.race
					playerIndex = playerIndex + 1
				end
				storageArgs['opponent' .. opponentIndex].players = players
			end
		end

		args['team' .. opponentIndex] = nil
		args['score' .. opponentIndex] = nil
	end
end

return MatchMapsTeamLegacy
