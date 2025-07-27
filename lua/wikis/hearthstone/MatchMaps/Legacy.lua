---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Template = require('Module:Template')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacy = {}

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 10

---@param args table
---@return table
function MatchMapsLegacy._mergeDetailsIntoArgs(args)
	local details = Json.parseIfTable(Table.extract(args, 'details')) or {}

	return Table.merge(details, args, {
		date = details.date or args.date,
		dateheader = Logic.isNotEmpty(args.date),
		header = Table.extract(args, 'title')
	})
end

---@param matchArgs table
function MatchMapsLegacy._readOpponents(matchArgs)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		matchArgs['opponent' .. opponentIndex] = {
			name = Table.extract(matchArgs, 'p' .. opponentIndex),
			flag = Table.extract(matchArgs, 'p' .. opponentIndex .. 'flag'),
			score = Table.extract(matchArgs, 'p' .. opponentIndex .. 'score')
				or Table.extract(matchArgs, 'score' .. opponentIndex),
			type = Opponent.solo
		}
	end)
end


---@param matchArgs table
function MatchMapsLegacy._readMaps(matchArgs)
	Array.forEach(Array.range(1, MAX_NUM_MAPS), function(mapIndex)
		local mapArgs = {
			winner = Table.extract(matchArgs, 'win' .. mapIndex),
			o1c1 = Table.extract(matchArgs, 'p1class' .. mapIndex),
			o2c1 = Table.extract(matchArgs, 'p2class' .. mapIndex),
			vod = Table.extract(matchArgs, 'vodgame' .. mapIndex)
		}
		matchArgs['map' .. mapIndex] = Logic.nilIfEmpty(mapArgs)
	end)
end

-- invoked by Template:MatchMaps or Template:MatchMapsNew
---@param frame Frame
---@return string|Html
function MatchMapsLegacy.convertMatch(frame)
	local matchArgs = MatchMapsLegacy._mergeDetailsIntoArgs(Arguments.getArgs(frame))

	MatchMapsLegacy._readOpponents(matchArgs)
	MatchMapsLegacy._readMaps(matchArgs)

	if Logic.readBool(matchlistVars:get('isOldMatchList')) then
		return Json.stringify(matchArgs)
	else
		Template.stashReturnValue(matchArgs, 'LegacyMatchlist')
		return mw.html.create('div'):css('display', 'none')
	end
end

---@param store boolean?
---@return boolean
function MatchMapsLegacy._shouldStore(store)
	return Logic.nilOr(
		Logic.readBoolOrNil(store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
end

function MatchMapsLegacy._start(args)
	assert(args.id, 'Missing id')

	local hide = Logic.nilOr(Logic.readBoolOrNil(args.hide), true)
	local store = MatchMapsLegacy._shouldStore(Table.extract(args, 'store'))
	local matchListArgs = {
		isLegacy = true,
		id = args.id,
		title = Logic.nilOr(args.title, args[1]),
		width = args.width or '300px',
		collapsed = hide,
		attached = hide,
		store = store,
		noDuplicateCheck = not store,
		gsl = Logic.isNotEmpty(args.gsl) and args.gsl .. 'first' or nil
	}

	return matchListArgs
end

-- invoked by Template:LegacyMatchList
---@param frame Frame
---@return string
function MatchMapsLegacy.matchList(frame)
	local args = Arguments.getArgs(frame)
	local matchListArgs = MatchMapsLegacy._start(args)

	globalVars:set('islegacy', 'true')
	matchlistVars:set('isOldMatchList', 'true')

	for _, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(matchJson) --[[@as table]]
		matchListArgs['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		match.vod = match.vod or args['vod' .. matchIndex]
		matchListArgs['M' .. matchIndex] = Json.stringify(match)
	end

	matchlistVars:delete('isOldMatchList')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(matchListArgs)
end

-- invoked by Template:LegacyMatchListStart
---@param frame Frame
function MatchMapsLegacy.matchListStart(frame)
	local args = Arguments.getArgs(frame)
	local matchListArgs = MatchMapsLegacy._start(args)
	Template.stashReturnValue(matchListArgs, 'LegacyMatchlist')
	globalVars:set('islegacy', 'true')
end

-- invoked by MatchListEnd
---@return string
function MatchMapsLegacy.matchListEnd()
	local matches = Template.retrieveReturnValues('LegacyMatchlist')
	local matchListArgs = table.remove(matches, 1)

	local gsl = matchListArgs.gsl
	Array.forEach(matches, function(match, matchIndex)
		if not gsl then
			matchListArgs['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		end
		matchListArgs['M' .. matchIndex] = Json.stringify(match)
	end)

	globalVars:delete('islegacy')
	return MatchGroup.MatchList(matchListArgs)
end
return MatchMapsLegacy
