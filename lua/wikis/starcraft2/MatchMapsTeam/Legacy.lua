---
-- @Liquipedia
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

local _match2Args
local _args
local _opponentPlayers = {{}, {}}

local _NUMBER_OF_OPPONENTS = 2

-- invoked by Template:Match maps team
function MatchMapsTeamLegacy.preprocess(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsTeamLegacy._preProcess(args)
end

function MatchMapsTeamLegacy._preProcess(args)
	_match2Args = Json.parse(args.details or '{}')

	args.details = nil
	_args = args

	MatchMapsTeamLegacy._handleMaps()

	MatchMapsTeamLegacy._handleOpponents()

	if args.date then
		args.dateheader = true
	end

	Template.stashReturnValue(Table.merge(args, _match2Args), 'LegacyMatchlist')
end

function MatchMapsTeamLegacy._handleMaps()
	local gameIndex = 1
	local prefix = 'm' .. gameIndex
	local map = _match2Args[prefix .. 'map']
	local mapWinner = _match2Args[prefix .. 'win']

	while map or mapWinner do
		_match2Args['map' .. gameIndex] = MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner, gameIndex)

		gameIndex = gameIndex + 1
		prefix = 'm' .. gameIndex
		map = _match2Args[prefix .. 'map']
		mapWinner = _match2Args[prefix .. 'win']
	end

	prefix = 'ace'
	map = _match2Args[prefix .. 'map']
	mapWinner = _match2Args[prefix .. 'win']

	if map or mapWinner then
		_match2Args['map' .. gameIndex] = MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner, gameIndex)
	end
end

function MatchMapsTeamLegacy._processSingleMap(prefix, map, mapWinner, gameIndex)
	local archon = Logic.readBool(_match2Args[prefix .. 'archon'])

	local mapArgs = {
		map = map or 'unknown',
		winner = mapWinner,
		vod = _match2Args['vodgame' .. gameIndex],
	}
	mapArgs = MatchMapsTeamLegacy._processMapOpponent(1, prefix, mapArgs, archon)
	mapArgs = MatchMapsTeamLegacy._processMapOpponent(2, prefix, mapArgs, archon)

	MatchMapsTeamLegacy._removeProcessedMapInput(prefix)

	return mapArgs
end

function MatchMapsTeamLegacy._processMapOpponent(side, prefix, mapArgs, archon)
	local addToMapArgs = {
		['t' .. side .. 'p1'] = String.isNotEmpty(_match2Args[prefix .. 'p' .. side .. 'link'])
			and _match2Args[prefix .. 'p' .. side .. 'link']
			or _match2Args[prefix .. 'p' .. side],
		['t' .. side .. 'p1race'] = _match2Args[prefix .. 'p' .. side .. 'race'],
		['t' .. side .. 'p1flag'] = _match2Args[prefix .. 'p' .. side .. 'flag'],

		['opponent' .. side .. 'archon'] = archon and 'true' or nil,
		['opponent' .. side .. 'race'] = archon and _match2Args[prefix .. 'p' .. side .. 'race'] or nil,

		['t' .. side .. 'p2'] = String.isNotEmpty(_match2Args[prefix .. 't' .. side .. 'p2link'])
			and _match2Args[prefix .. 't' .. side .. 'p2link']
			or _match2Args[prefix .. 't' .. side .. 'p2'],
		['t' .. side .. 'p2race'] = _match2Args[prefix .. 't' .. side .. 'p2race'],
		['t' .. side .. 'p2flag'] = _match2Args[prefix .. 't' .. side .. 'p2flag'],

		['t' .. side .. 'p3'] = String.isNotEmpty(_match2Args[prefix .. 't' .. side .. 'p3link'])
			and _match2Args[prefix .. 't' .. side .. 'p3link']
			or _match2Args[prefix .. 't' .. side .. 'p3'],
		['t' .. side .. 'p3race'] = _match2Args[prefix .. 't' .. side .. 'p3race'],
		['t' .. side .. 'p3flag'] = _match2Args[prefix .. 't' .. side .. 'p3flag'],
	}

	MatchMapsTeamLegacy._setPlayersForOpponents(addToMapArgs, side, {
			_match2Args[prefix .. 'p' .. side],
			_match2Args[prefix .. 't' .. side .. 'p2'],
			_match2Args[prefix .. 't' .. side .. 'p3'],
	})

	return Table.mergeInto(mapArgs, addToMapArgs)
end

function MatchMapsTeamLegacy._setPlayersForOpponents(args, side, displayNames)
	local prefix = 't' .. side .. 'p'

	for playerKey, player, playerIndex in Table.iter.pairsByPrefix(args, prefix) do
		_opponentPlayers[side][player] = {
			race = args[playerKey .. 'race'],
			flag = args[playerKey .. 'flag'],
			display = displayNames[playerIndex],
		}
	end
end

function MatchMapsTeamLegacy._removeProcessedMapInput(prefix)
	for key, _ in pairs(_match2Args) do
		if String.startsWith(key, prefix) then
			_match2Args[key] = nil
		end
	end
end

function MatchMapsTeamLegacy._handleOpponents()
	local args = _args

	for opponentIndex = 1, _NUMBER_OF_OPPONENTS do
		if args['team' .. opponentIndex] and args['team' .. opponentIndex]:lower() == 'bye' then
			_match2Args['opponent' .. opponentIndex] = {
				['type'] = 'literal',
				name = 'BYE',
			}
		else
			_match2Args['opponent' .. opponentIndex] = {
				['type'] = 'team',
				template = args['team' .. opponentIndex],
				score = args['score' .. opponentIndex],
			}
			if args['team' .. opponentIndex] == '' then
				_match2Args['opponent' .. opponentIndex]['type'] = 'literal'
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
				_match2Args['opponent' .. opponentIndex].players = players
			end
		end

		args['team' .. opponentIndex] = nil
		args['score' .. opponentIndex] = nil
	end
end

return MatchMapsTeamLegacy
