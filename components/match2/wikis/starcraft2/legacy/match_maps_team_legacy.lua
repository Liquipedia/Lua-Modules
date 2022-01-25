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
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Template = require('Module:Template')
local Json = require('Module:Json')
local Table = require('Module:Table')
local Match = require('Module:Match')
local MatchGroup = require('Module:MatchGroup')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

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

	storageArgs.winner = args.winner
	storageArgs.bestof = args.bestof

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
		local archon = Logic.readBool(storageArgs[prefix .. 'archon'])

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

	local mapArgs = {
		map = map or 'unknown',
		winner = mapWinner,

		--opponent1 side
		t1p1 = String.isNotEmpty(storageArgs[prefix .. 'p1link'])
			and storageArgs[prefix .. 'p1link']
			or storageArgs[prefix .. 'p1'],
		t1p1race = storageArgs[prefix .. 'p1race'],

		opponent1archon = archon and 'true' or nil,
		opponent1race = archon and storageArgs[prefix .. 'p1race'] or nil,

		t1p2 = String.isNotEmpty(storageArgs[prefix .. 't1p2link'])
			and storageArgs[prefix .. 't1p2link']
			or storageArgs[prefix .. 't1p2'],
		t1p2race = storageArgs[prefix .. 't1p2race'],
		t1p3 = String.isNotEmpty(storageArgs[prefix .. 't1p3link'])
			and storageArgs[prefix .. 't1p3link']
			or storageArgs[prefix .. 't1p3'],
		t1p3race = storageArgs[prefix .. 't1p3race'],

		--opponent2 side
		t2p1 = String.isNotEmpty(storageArgs[prefix .. 'p2link'])
			and storageArgs[prefix .. 'p2link']
			or storageArgs[prefix .. 'p2'],
		t2p1race = storageArgs[prefix .. 'p2race'],

		opponent2archon = archon and 'true' or nil,
		opponent2race = archon and storageArgs[prefix .. 'p2race'] or nil,

		t2p2 = String.isNotEmpty(storageArgs[prefix .. 't2p2link'])
			and storageArgs[prefix .. 't2p2link']
			or storageArgs[prefix .. 't2p2'],
		t2p2race = storageArgs[prefix .. 't2p2race'],
		t2p3 = String.isNotEmpty(storageArgs[prefix .. 't2p3link'])
			and storageArgs[prefix .. 't2p3link']
			or storageArgs[prefix .. 't2p3'],
		t2p3race = storageArgs[prefix .. 't2p3race'],
	}

	MatchMapsTeamLegacy._setPlayersForOpponents(mapArgs)

	MatchMapsTeamLegacy._removeProcessedMapInput(prefix)

	return mapArgs
end

function MatchMapsTeamLegacy._setPlayersForOpponents(mapArgs)
	local index = 1
	while mapArgs['t1p' .. index] do
		_opponentPlayers[1][mapArgs['t1p' .. index]] = true
		index = index + 1
	end

	index = 1
	while mapArgs['t2p' .. index] do
		_opponentPlayers[2][mapArgs['t2p' .. index]] = true
		index = index + 1
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
				for player, _ in pairs(_opponentPlayers[opponentIndex]) do
					players['p' .. playerIndex] = player
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
