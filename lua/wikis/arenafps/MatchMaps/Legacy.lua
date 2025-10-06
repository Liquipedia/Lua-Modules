---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')

local globalVars = PageVariableNamespace()

local Opponent = Lua.import('Module:Opponent/Custom')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 9

local MatchMapsLegacy = {}

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

---@param matchArgs table
function MatchMapsLegacy._readOpponents(matchArgs)
	local matchMapsType
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		matchMapsType = matchMapsType or (matchArgs['player' .. opponentIndex] and Opponent.solo or
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
	matchMapsType = matchMapsType or Opponent.literal
	matchArgs['opponent1'].type = matchMapsType
	matchArgs['opponent2'].type = matchMapsType
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
		matchArgs[prefix] = Logic.isNotEmpty(mapArgs) and mapArgs or nil
	end)
end

-- invoked by Template:MatchMaps
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

-- invoked by Template:LegacySingleMatch
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

---@param frame any
---@return string
function MatchMapsLegacy.generate(frame)
	return MatchMapsLegacy.matchList(frame, true)
end

-- invoked by Template:LegacyMatchList
---@param frame Frame
---@param generate true?
---@return string
function MatchMapsLegacy.matchList(frame, generate)
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
	args[1] = nil

	for matchKey, _, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(Table.extract(args, matchKey)) --[[@as table]]
		args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		args['M' .. matchIndex] = Json.stringify(match)
	end

	globalVars:delete('islegacy')

	if generate then
		args.isLegacy = nil
		return MatchGroupLegacy.generateWikiCodeForMatchList(args)
	end

	return MatchGroup.MatchList(args)
end

---@param frame Frame
---@return string
function MatchMapsLegacy.generateSingleMatch(frame)
	local args = Arguments.getArgs(frame)
	args.generate = true

	assert(args.id, 'Missing id')

	return MatchGroupLegacy.generateWikiCodeForSingleMatch{
		match = MatchMapsLegacy.convertMatch(args),
		id = args.id,
	}
end

return MatchMapsLegacy
