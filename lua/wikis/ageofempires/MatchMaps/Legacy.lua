---
-- @Liquipedia
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
local Template = require('Module:Template')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MAX_NUMBER_OF_OPPONENTS = 2
local GSL_WINNERS = 'winners'
local GSL_LOSERS = 'losers'

local MatchMapsLegacy = {}

---@param args table
---@return table
function MatchMapsLegacy._mergeDetailsIntoArgs(args)
	local details = Json.parseIfTable(Table.extract(args, 'details')) or {}

	return Table.merge(details, args, {
		date = details.date or args.date,
		dateheader = Logic.isNotEmpty(args.date),
		header = Table.extract(args, 'title') or Table.extract(args, 'subtitle')
	})
end

---@param matchArgs table
function MatchMapsLegacy._readOpponents(matchArgs)
	local matchMapsType
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local opponent = {
			score = Table.extract(matchArgs, 'score' .. opponentIndex) or
				Table.extract(matchArgs, 'p' .. opponentIndex .. 'score'),
			template = Table.extract(matchArgs, 'team' .. opponentIndex),
			name = Table.extract(matchArgs, 'p' .. opponentIndex) or
				Table.extract(matchArgs, 'player' .. opponentIndex),
			link = Table.extract(matchArgs, 'p' .. opponentIndex .. 'link') or
				Table.extract(matchArgs, 'player' .. opponentIndex .. 'link'),
			flag = Table.extract(matchArgs, 'p' .. opponentIndex .. 'flag'),
		}

		matchMapsType = matchMapsType or (opponent.name and Opponent.solo or
			opponent.template and Opponent.team) or nil
		matchArgs['opponent' .. opponentIndex] = opponent
	end)
	matchMapsType = matchMapsType or Opponent.literal
	matchArgs['opponent1'].type = matchMapsType
	matchArgs['opponent2'].type = matchMapsType
end

---@param matchArgs table
function MatchMapsLegacy._readMaps(matchArgs)
	for mapKey, value in Table.iter.pairsByPrefix(matchArgs, 'map') do
		matchArgs[mapKey] = Json.parseIfTable(value)
	end
	--handle MatchMaps mapXwin
	local mapWinners = Table.filterByKey(matchArgs, function (key)
		local winner = key:match('map(%d+)win')
		return winner ~= nil
	end)
	Table.iter.forEachPair(mapWinners, function (key)
		local mapKey = key:match('(map%d+)')
		local mapWinner = Table.extract(matchArgs, mapKey .. 'win')
		matchArgs[mapKey] = matchArgs[mapKey] or {}
		matchArgs[mapKey].winner = matchArgs[mapKey].winner or mapWinner
	end)
end

-- invoked by Template:MatchMaps
---@param frame Frame
---@return Html
function MatchMapsLegacy.convertMatch(frame)
	local matchArgs = MatchMapsLegacy._mergeDetailsIntoArgs(Arguments.getArgs(frame))
	MatchMapsLegacy._readOpponents(matchArgs)
	MatchMapsLegacy._readMaps(matchArgs)
	matchArgs.winner = matchArgs.winner or Table.extract(matchArgs, 'win')

	Template.stashReturnValue(matchArgs, 'LegacyMatchlist')
	return mw.html.create('div'):css('display', 'none')
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
	local args = Arguments.getArgs(frame)
	local id = args.id
	assert(id, 'Missing id')
	local match = Template.retrieveReturnValues('LegacyMatchlist')[1]

	local store = MatchMapsLegacy._shouldStore(Table.extract(args, 'store'))
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
		width = args.width
	})
end

---@param frame Frame
function MatchMapsLegacy.matchlistStart(frame)
	local args = Arguments.getArgs(frame)

	local store = MatchMapsLegacy._shouldStore(Table.extract(args, 'store'))

	globalVars:set('islegacy', 'true')
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '320px')
	matchlistVars:set('matchsection', args.matchsection)
	matchlistVars:set('hide', args.hide or 'true')
	matchlistVars:set('store', store and 'true' or nil)
	matchlistVars:set('gsl', args.gsl or matchlistVars:get('gsl'))
end

---@return string?
function MatchMapsLegacy.matchlistEnd()
	local bracketid = matchlistVars:get('bracketid')
	if Logic.isEmpty(bracketid) then return end

	local matchListArgs = {
		isLegacy = true,
		id = bracketid,
		title = matchlistVars:get('matchListTitle'),
		width = matchlistVars:get('width'),
		matchsection = matchlistVars:get('matchsection'),
	}

	local gsl = matchlistVars:get('gsl')
	if Logic.isNotEmpty(gsl) then
		if gsl == GSL_WINNERS or gsl == GSL_LOSERS then
			gsl = gsl .. 'first'
			matchListArgs['gsl'] = gsl
		end
	end

	local matches = Template.retrieveReturnValues('LegacyMatchlist') --[[@as table]]
	Array.forEach(matches, function(match, matchIndex)
		if not matchListArgs['gsl'] then
			matchListArgs['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		end
		matchListArgs['M' .. matchIndex] = Json.stringify(match)
	end)

	if Logic.readBool(matchlistVars:get('hide')) then
		matchListArgs.collapsed = true
		matchListArgs.attached = true
	else
		matchListArgs.collapsed = false
	end
	if Logic.readBool(matchlistVars:get('store')) then
		matchListArgs.store = true
	else
		matchListArgs.noDuplicateCheck = true
		matchListArgs.store = false
	end

	globalVars:delete('islegacy')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('width')
	matchlistVars:delete('matchsection')
	matchlistVars:delete('hide')
	matchlistVars:delete('store')
	matchlistVars:delete('gsl')

	return MatchGroup.MatchList(matchListArgs)
end

return MatchMapsLegacy
