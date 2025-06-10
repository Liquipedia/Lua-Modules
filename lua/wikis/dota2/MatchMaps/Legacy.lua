---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacy = {}

local DEFAULT = 'default'
local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_PICKS = 5
local MAX_NUMBER_OF_BANS = 7
local TBD = 'tbd'
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'
local FORFEIT = 'FF'

local GSL_WINNERS = 'winners'
local GSL_LOSERS = 'losers'
local GSL_SEEDING = 'seeding'

---@param args table
---@return table
function MatchMapsLegacy._convertMaps(args)
	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local map = Json.parse(matchJson) or {}
		map.winner = map.win
		map.win = nil
		local mapKey = 'map' .. matchIndex
		for key, value in pairs(map) do
			args[mapKey .. key] = value
		end
		args[matchKey] = nil
	end
	return args
end

-- invoked by Template:BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args = MatchMapsLegacy._convertMaps(args)
	return Json.stringify(args)
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy._handleDetails(args, details)
	local getMapFromDetails = function (index)
		local prefix = 'map' .. index
		if not details[prefix] then
			return nil
		end
		local map = {}
		map.map = details[prefix]
		map.winner = Table.extract(details, prefix .. 'winner')
		--Try to get winner from "MatchMaps"
		if Logic.isEmpty(map.winner) then
			map.winner = args[prefix .. 'win']
		end

		if details[prefix .. 'length'] and details[prefix .. 'length']:lower() == DEFAULT then
			map.walkover = map.winner
		end

		map.length = Table.extract(details, prefix .. 'length')

		Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(oppIndex)
			local side = 'team' .. oppIndex .. 'side'
			map[side] = Table.extract(details, prefix .. side)

			Array.forEach(Array.range(1, MAX_NUMBER_OF_BANS), function (playerIndex)
				--There are more bans than picks
				if playerIndex <= MAX_NUMBER_OF_PICKS then
					local pick = 't' .. oppIndex .. 'h' .. playerIndex
					map[pick] = Table.extract(details, prefix .. pick)
				end
				local ban = 't' .. oppIndex .. 'b' .. playerIndex
				map[ban] = Table.extract(details, prefix .. ban)
			end)
		end)
		details[prefix] = nil
		return map
	end

	local getMapOnlyWithWinner = function (index)
		if not args['map' .. index .. 'win'] then
			return nil
		end
		return {
			winner = args['map' .. index .. 'win'],
		}
	end

	Array.mapIndexes(function (index)
		local map = getMapFromDetails(index) or getMapOnlyWithWinner(index)
		if map and map.winner then
			args.mapWinnersSet = true
		end
		args['map' .. index] = map
		args['map' .. index .. 'win'] = nil
		details['match' .. index] = nil
		return map
	end)

	return args, details
end

---@param args table
---@return table
function MatchMapsLegacy._handleOpponents(args)
	args.winner = args.winner or args.win

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(opponentIndex)
		local template = Table.extract(args, 'team' .. opponentIndex) or Table.extract(args , 'player' .. opponentIndex)

		if (not template) or template == '&nbsp;' then
			template = TBD
		else
			template = string.lower(template)
		end

		local score
		local winner = tonumber(args.winner)
		if args.walkover then
			local walkover = tonumber(args.walkover)
			if walkover and walkover ~= 0 then
				score = walkover == opponentIndex and DEFAULT_WIN or FORFEIT
			else
				score = args['score' .. opponentIndex]
			end
		elseif args['score' .. opponentIndex] then
			score = args['score' .. opponentIndex]
		elseif not args.mapWinnersSet and winner then
			score = winner == opponentIndex and DEFAULT_WIN or DEFAULT_LOSS
		end

		local opponent
		if template ~= TBD then
			opponent = {
				['type'] = 'team',
				score = score,
				template = template,
			}
		end
		if Logic.isEmpty(opponent) then
			opponent = {
				['type'] = 'literal',
				template = TBD,
				name = Table.extract(args, 'team' .. opponentIndex .. 'dota')
			}
		end
		args['opponent' .. opponentIndex] = opponent

		args['score' .. opponentIndex] = nil
	end)

	args.win = nil
	args.walkover = nil
	args.mapWinnersSet = nil

	return args
end

---@param args table
---@param details table
---@return table
function MatchMapsLegacy._setHeaderIfEmpty(args, details)
	args.header = args.header or args.subtitle or args.date
	args.date = details.date or args.date
	args.subtitle = nil
	return args
end

---@param args table
---@param details table
---@return table
function MatchMapsLegacy._copyDetailsToArgs(args, details)
	for key, value in pairs(details) do
		if Logic.isEmpty(args[key]) then
			args[key] = value
		end
	end
	args.details = nil
	return args
end

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return string|Html
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local details = Json.parseIfString(args.details or '{}')

	args, details = MatchMapsLegacy._handleDetails(args, details)
	args = MatchMapsLegacy._handleOpponents(args)
	args = MatchMapsLegacy._setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy._copyDetailsToArgs(args, details)

	if Logic.readBool(matchlistVars:get('isOldMatchList')) then
		return Json.stringify(args)
	else
		Template.stashReturnValue(args, 'LegacyMatchlist')
		return mw.html.create('div'):css('display', 'none')
	end
end

-- invoked by Template:LegacySingleMatch
---@param frame Frame
---@return Html
function MatchMapsLegacy.showmatch(frame)
	local args = Arguments.getArgs(frame)
	assert(args.id, 'Missing id')

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	MatchGroup.Bracket({
		'Bracket/2',
		isLegacy = true,
		id = args.id,
		hide = true,
		store = store,
		noDuplicateCheck = not store,
		R1M1 = matches[1]
	})

	return MatchGroup.MatchByMatchId({
		id = MatchGroupBase.getBracketIdPrefix() .. args.id,
		width = args.width or '430px',
		matchid = 'R1M1',
	})
end

-- invoked by Template:MatchList
---@param frame Frame
---@return string
function MatchMapsLegacy.matchList(frame)
	local args = Arguments.getArgs(frame)
	assert(args.id, 'Missing id')

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
	local hide = Logic.nilOr(Logic.readBoolOrNil(args.hide), true)
	args.isLegacy = true
	args.store = store
	args.noDuplicateCheck = not store
	args.collapsed = hide
	args.attached = hide
	args.title = Logic.nilOr(args.title, args[1])
	args.width = args.width or '300px'

	matchlistVars:set('isOldMatchList', 'true')
	globalVars:set('islegacy', 'true')

	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(matchJson)
		args['M' .. matchIndex .. 'header'] = match.header
		match.header = nil
		args['M' .. matchIndex] = Json.stringify(match)
		args[matchKey] = nil
	end

	matchlistVars:delete('isOldMatchList')
	globalVars:delete('islegacy')

	args[1] = nil
	args.hide = nil

	return MatchGroup.MatchList(args)
end

-- invoked by Template:MatchListStart
---@param frame Frame
function MatchMapsLegacy.matchListStart(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '300px')
	matchlistVars:set('hide', args.hide or 'true')
	matchlistVars:set('matchsection', args.matchsection)
	matchlistVars:set('gsl', args.gsl or matchlistVars:get('gsl'))
	globalVars:set('islegacy', 'true')
end

-- invoked by MatchListEnd
---@return string
function MatchMapsLegacy.matchListEnd()
	local bracketId = matchlistVars:get('bracketid')
	assert(bracketId, 'Missing id')

	local store = Logic.readBool(matchlistVars:get('store'))
	local hide = Logic.readBool(matchlistVars:get('hide'))

	local args = {
		isLegacy = true,
		id = bracketId,
		store = store,
		noDuplicateCheck = not store,
		collapsed = hide,
		attached = hide,
		title = matchlistVars:get('matchListTitle'),
		width = matchlistVars:get('width'),
		matchsection = matchlistVars:get('matchsection'),
	}

	local gsl = matchlistVars:get('gsl') --[[@as string]]
	if Logic.isNotEmpty(gsl) then
		gsl = gsl:lower()
		if String.endsWith(gsl, GSL_WINNERS) then
			gsl = 'winnersfirst'
		elseif String.endsWith(gsl, GSL_SEEDING) then
			gsl = 'winnersfirst'
			args['M4header'] = 'Losers Match'
		elseif String.endsWith(gsl, GSL_LOSERS) then
			if String.startsWith(gsl, GSL_SEEDING) then
				args['M3header'] = 'Losers Match'
			end
			gsl = 'losersfirst'
		end
		args['gsl'] = gsl
	end

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	Array.forEach(matches, function(match, matchIndex)
		if Logic.isEmpty(gsl) then
			args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		end
		args['M' .. matchIndex] = Json.stringify(match)
	end)

	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('width')
	matchlistVars:delete('hide')
	matchlistVars:delete('matchsection')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
