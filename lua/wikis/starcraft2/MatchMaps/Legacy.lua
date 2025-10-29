---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local String = Lua.import('Module:StringUtils')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Template = Lua.import('Module:Template')
local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacy = {}

local _storageArgs

local _NUMBER_OF_OPPONENTS = 2

-- invoked by Template:Legacy Match list start
function MatchMapsLegacy.init(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacy._init(args)
end

function MatchMapsLegacy._init(args)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width)
	matchlistVars:set('hide', args.hide or 'true')
end


-- invoked by Template:Match maps
function MatchMapsLegacy.preprocess(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacy._preProcess(args)
end

function MatchMapsLegacy._preProcess(args)
	_storageArgs = args
	MatchMapsLegacy._handleOpponents()
	MatchMapsLegacy._handleMaps()

	if args.date then
		args.dateheader = true
	end

	-- all other args from the match maps calls are just passed along directly
	-- as they can be read by the match2 processing

	Template.stashReturnValue(args, 'LegacyMatchlist')
end

function MatchMapsLegacy._handleOpponents()
	local storageArgs = _storageArgs

	for opponentIndex = 1, _NUMBER_OF_OPPONENTS do
		if storageArgs['player' .. opponentIndex] and storageArgs['player' .. opponentIndex]:lower() == 'bye' then
			storageArgs['opponent' .. opponentIndex] = {
				['type'] = 'literal',
				name = 'BYE',
			}
		else
			storageArgs['opponent' .. opponentIndex] = {
				['type'] = 'solo',
				name = storageArgs['player' .. opponentIndex],
				link = storageArgs['playerlink' .. opponentIndex],
				race = storageArgs['player' .. opponentIndex .. 'race'],
				flag = storageArgs['player' .. opponentIndex .. 'flag'],
				score = storageArgs['p' .. opponentIndex .. 'score'],
			}
			if storageArgs['player' .. opponentIndex] == '' then
				storageArgs['opponent' .. opponentIndex]['type'] = 'literal'
			end
		end

		storageArgs['player' .. opponentIndex] = nil
		storageArgs['playerlink' .. opponentIndex] = nil
		storageArgs['player' .. opponentIndex .. 'race'] = nil
		storageArgs['player' .. opponentIndex .. 'flag'] = nil
		storageArgs['p' .. opponentIndex .. 'score'] = nil
	end
end

function MatchMapsLegacy._handleMaps()
	local storageArgs = _storageArgs

	local gameIndex = 1
	local map = storageArgs['map' .. gameIndex]
	local mapWinner = storageArgs['map' .. gameIndex .. 'win']

	while map or mapWinner do
		storageArgs['map' .. gameIndex] = {
			map = map,
			winner = mapWinner,
			race1 = storageArgs['map' .. gameIndex .. 'p1race'],
			race2 = storageArgs['map' .. gameIndex .. 'p2race'],
			vod = storageArgs['vodgame' .. gameIndex],
		}

		storageArgs['map' .. gameIndex .. 'win'] = nil
		storageArgs['map' .. gameIndex .. 'p1race'] = nil
		storageArgs['map' .. gameIndex .. 'p2race'] = nil

		gameIndex = gameIndex + 1
		map = storageArgs['map' .. gameIndex]
		mapWinner = storageArgs['map' .. gameIndex .. 'win']
	end
end


-- invoked by Template:Match list end
function MatchMapsLegacy.close()
	local bracketId = matchlistVars:get('bracketid')
	-- since the same template is also used for old team match lists
	-- that are not yet converted we need to return an empty string
	-- in case we have no bracketId
	if String.isEmpty(bracketId) then
		return ''
	end

	local matches = Template.retrieveReturnValues('LegacyMatchlist') --[[@as table]]

	for matchIndex, match in ipairs(matches) do
		matches['M' .. matchIndex] = Match.makeEncodedJson(match)
		matches[matchIndex] = nil
	end

	matches.id = bracketId
	matches.isLegacy = true
	matches.title = matchlistVars:get('matchListTitle')
	matches.width = matchlistVars:get('width')
	if matchlistVars:get('hide') == 'true' then
		matches.collapsed = true
		matches.attached = true
	else
		matches.collapsed = false
	end
	if Logic.readBool(matchlistVars:get('store')) then
		matches.store = true
	else
		matches.noDuplicateCheck = true
		matches.store = false
	end

	-- generate Display
	-- this also stores the MatchData
	local matchHtml = MatchGroup.MatchList(matches)

	MatchMapsLegacy._resetVars()

	return matchHtml
end

function MatchMapsLegacy._resetVars()
	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
end

return MatchMapsLegacy
