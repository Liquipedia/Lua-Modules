---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')
local MatchSubobjects = Lua.import('Module:Match/Subobjects')

local globalVars = PageVariableNamespace()

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 9
local DRAW = 'draw'
local SKIP = 'skip'

local MatchMapsLegacy = {}

---@param args table
---@return table
function MatchMapsLegacy._handleMaps(args)
	Array.mapIndexes(function(index)
		local prefix = 'map' .. index
		local map = args[prefix]
		local winner = Table.extract(args, prefix .. 'win')
		local score = Table.extract(args, prefix .. 'score')
		if Logic.isEmpty(map) and Logic.isEmpty(winner) then
			return false
		end

		if Logic.isNotEmpty(score) then
			local splitedScore = Array.parseCommaSeparatedString(score, '-')
			args[prefix .. 'score1'] = mw.text.decode(splitedScore[1])
			args[prefix .. 'score2'] = mw.text.decode(splitedScore[2])
		end

		args[prefix .. 'finished'] = (winner == SKIP and SKIP) or
			(not Logic.isEmpty(winner) and 'true') or 'false'

		if Logic.isNumeric(winner) or winner == DRAW then
			args[prefix .. 'winner'] = winner == DRAW and 0 or winner
		end
		return true
	end)

	return args
end

-- invoked by BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args = MatchMapsLegacy._handleMaps(args)

	return Json.stringify(args)
end

---@param args table
---@return table
function MatchMapsLegacy._mergeDetailsIntoArgs(args)
	local details = Json.parseIfTable(Table.extract(args, 'details')) or {}

	return Table.merge(details, args, {
		date = details.date or args.date,
		dateheader = Logic.isNotEmpty(args.date),
		header = Table.extract(args, 'header')
	})
end

function MatchMapsLegacy._readOpponents(matchArgs)
	local type
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		type = type or (matchArgs['player' .. opponentIndex] and Opponent.solo or
			matchArgs['team' .. opponentIndex] and Opponent.team) or nil
			matchArgs['opponent' .. opponentIndex] = {
			score = Table.extract(matchArgs, 'score' .. opponentIndex) or
				Table.extract(matchArgs, 'games' .. opponentIndex),
			template = Table.extract(matchArgs, 'team' .. opponentIndex),
			name = Table.extract(matchArgs, 'player' .. opponentIndex),
			link = Table.extract(matchArgs, 'playerlink' .. opponentIndex),
			flag = Table.extract(matchArgs, 'player' .. opponentIndex .. 'flag'),
		}
	end)
	matchArgs['opponent1'].type = type
	matchArgs['opponent2'].type = type
end

---@param matchArgs table
function MatchMapsLegacy._readMaps(matchArgs)
	Array.forEach(Array.range(1, MAX_NUM_MAPS), function(mapIndex)
		local prefix = 'map' .. mapIndex
		local mapArgs = {
			map = Table.extract(matchArgs, prefix),
			finished = Table.extract(matchArgs, prefix .. 'finished'),
			winner = Table.extract(matchArgs, prefix .. 'winner'),
			score1 = Table.extract(matchArgs, prefix .. 'score1'),
			score2 = Table.extract(matchArgs, prefix .. 'score2'),
			vod = Table.extract(matchArgs, 'vodgame' .. mapIndex)
		}
		matchArgs[prefix] = Logic.isNotEmpty(mapArgs) and MatchSubobjects.luaGetMap(mapArgs) or nil
	end)
end

-- invoked by Template:MatchMaps/Showmatch
---@param frame Frame
---@return string
function MatchMapsLegacy.convertMatch(frame)
	local matchArgs = MatchMapsLegacy._mergeDetailsIntoArgs(Arguments.getArgs(frame))
	MatchMapsLegacy._readOpponents(matchArgs)
	MatchMapsLegacy._readMaps(matchArgs)
	matchArgs.winner = matchArgs.winner or Table.extract(matchArgs, 'win')

	return Json.stringify(matchArgs)
end

---@param store boolean?
---@return boolean
function MatchMapsLegacy._shouldStore(store)
	return Logic.nilOr(
		Logic.readBoolOrNil(store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
end

---@param frame Frame
---@return Html
function MatchMapsLegacy.showmatch(frame)
	local match = Json.parseIfString(MatchMapsLegacy.convertMatch(frame))
	local id = Table.extract(match, 'id')
	assert(id, 'Missing id')

	local store = MatchMapsLegacy._shouldStore(Table.extract(match, 'store'))
	MatchGroup.Bracket({
		'Bracket/2',
		isLegacy = true,
		id = id,
		hide = true,
		store = store,
		noDuplicateCheck = not store,
		R1M1 = match
	})

	return MatchGroup.MatchByMatchId({
		id = MatchGroupBase.getBracketIdPrefix() .. id,
		matchid = 'R1M1',
	})
end

-- invoked by Template:MatchList
---@param frame Frame
---@return string
function MatchMapsLegacy.matchList(frame)
	globalVars:set('islegacy', 'true')
	local args = Arguments.getArgs(frame)
	assert(args.id, 'Missing id')
	local store = MatchMapsLegacy._shouldStore(args.store)
	local hide = Logic.nilOr(Logic.readBoolOrNil(args.hide), true)

	Table.mergeInto(args, {
		isLegacy = true,
		store = store,
		noDuplicateCheck = not store,
		collapsed = hide,
		attached = hide,
		title = Logic.nilOr(Table.extract(args, 'title'), args[1]),
		width = Table.extract(args, 'width') or '300px',
	})
	args.width = (args.width or ''):gsub('px', '')
	args[1] = nil

	for matchKey, _, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(Table.extract(args, matchKey)) --[[@as table]]
		args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		args['M' .. matchIndex] = Json.stringify(match)
	end

	globalVars:delete('islegacy')
	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
