---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchMapsLegacy = {}

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')
local MatchSubobjects = Lua.import('Module:Match/Subobjects')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local DECIDER = 'decider'
local DRAW = 'draw'
local SKIP = 'skip'
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'
local FORFEIT = 'FF'
local TBD = 'tbd'

local GSL_GF = 'gf'
local GSL_WINNERS = 'winners'
local GSL_LOSERS = 'losers'

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_PLAYERS = 5

---@param prefix string
---@param args table
---@return table
function MatchMapsLegacy._handlePlayersStats(prefix, args)
	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(opponentIndex)
		local teamKey = prefix .. 't' .. opponentIndex
		Array.forEach(Array.range(1, MAX_NUMBER_OF_PLAYERS), function(playerIndex)
			local player = args[teamKey .. 'p' .. playerIndex]
			local kda = Table.extract(args, teamKey .. 'kda' .. playerIndex) or ''
			local kills, deaths, assists = kda:match("(%d+)%/(%d+)%/(%d+)")

			args[teamKey .. 'p' .. playerIndex] = Json.stringify({
				player = player,
				agent = Table.extract(args, teamKey .. 'a' .. playerIndex),
				kills = kills,
				deaths = deaths,
				assists = assists,
				acs = Table.extract(args, teamKey .. 'acs' .. playerIndex)
			})
		end)
	end)

	return args
end

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
			args[prefix .. 'score1'] = splitedScore[1]
			args[prefix .. 'score2'] = splitedScore[2]
		end

		args[prefix .. 'finished'] = (winner == SKIP and SKIP) or
			(not Logic.isEmpty(winner) and 'true') or 'false'

		if Logic.isNumeric(winner) or winner == DRAW then
			args[prefix .. 'winner'] = winner == DRAW and 0 or winner
		end

		args[prefix .. 't1firstsideot'] = Table.extract(args, prefix .. 'o1t1firstside')
		args[prefix .. 't1otatk'] = Table.extract(args, prefix .. 'o1t1atk')
		args[prefix .. 't1otdef'] = Table.extract(args, prefix .. 'o1t1def')
		args[prefix .. 't2otatk'] = Table.extract(args, prefix .. 'o1t2atk')
		args[prefix .. 't2otdef'] = Table.extract(args, prefix .. 'o1t2def')

		local vod = Table.extract(args, 'vodgame' .. index)
		if Logic.isEmpty(vod) then
			vod = Table.extract(args, 'vod' .. index)
		end
		args[prefix .. 'vod'] = vod

		args = MatchMapsLegacy._handlePlayersStats(prefix, args)
		return true
	end)

	return args
end

-- invoked by BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args.mapveto = Table.extract(args, 'mapbans')
	args = MatchMapsLegacy._handleMaps(args)

	return Json.stringify(args)
end

-- invoked by MapVetoTableSmall
---@param frame Frame
---@return string
function MatchMapsLegacy.convertMapVeto(frame)
	local args = Arguments.getArgs(frame)
	args.firstpick = Table.extract(args, 'firstban')
	local vetoTypes = {}
	for vetoKey, vetoType, vetoIndex in Table.iter.pairsByPrefix(args, 'r') do
		table.insert(vetoTypes, vetoType)
		if vetoType == DECIDER then
			args.decider = args['map' .. vetoIndex]
			args['map' .. vetoIndex] = nil
		end
		args[vetoKey] = nil
	end
	args.types = table.concat(vetoTypes, ',')

	return Json.stringify(args)
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy._handleDetails(args, details)
	Array.mapIndexes(function(index)
		local prefix = 'map' .. index
		if Logic.isEmpty(details[prefix]) and Logic.isEmpty(details[prefix .. 'finished']) then
			return false
		end

		local map = {}
		for key, value in pairs(details) do
			if String.startsWith(key, prefix) then
				local newKey = key:gsub(prefix, '')
				newKey = String.isEmpty(newKey) and 'map' or newKey
				map[newKey] = value
				details[key] = nil
			end
		end

		if map and map.winner then
			args.mapWinnersSet = true
		end

		args[prefix] = MatchSubobjects.luaGetMap(map)
		return true
	end)

	return args, details
end

---@param args table
---@return table
function MatchMapsLegacy._handleOpponents(args)
	args.winner = args.winner or args.win
	for index = 1, MAX_NUMBER_OF_OPPONENTS do
		args['score' .. index] = args['score' .. index] or args['games' .. index]
		local template = Table.extract(args, 'team' .. index)
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
				score = walkover == index and DEFAULT_WIN or FORFEIT
			else
				score = args['score' .. index]
			end
		elseif args['score' .. index] then
			score = args['score' .. index]
		elseif not args.mapWinnersSet and winner then
			score = winner == index and DEFAULT_WIN or DEFAULT_LOSS
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
				name = args['opponent' .. index .. 'valorant']
			}
		end
		args['opponent' .. index] = opponent
		args['score' .. index] = nil
		args['games' .. index] = nil
	end
	args.win = nil
	args.walkover = nil
	args.mapWinnersSet = nil

	return args
end

---@param args table
---@param details table
---@return table
function MatchMapsLegacy._setHeaderIfEmpty(args, details)
	args.header = args.header or args.date
	args.date = details.date or args.date
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

-- invoked by Template:MatchMaps
---@param frame Frame
---@return Html
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local details = Json.parseIfString(args.details or '{}')

	args, details = MatchMapsLegacy._handleDetails(args, details)
	args = MatchMapsLegacy._handleOpponents(args)
	args = MatchMapsLegacy._setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy._copyDetailsToArgs(args, details)

	Template.stashReturnValue(args, 'LegacyMatchlist')
	return mw.html.create('div'):css('display', 'none')
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
		width = args.width or '500px',
		matchid = 'R1M1',
	})
end

-- invoked by Template:LegacyMatchListStart
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
	matchlistVars:set('gsl', args.gsl)
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
		if String.endsWith(gsl:lower(), GSL_WINNERS) then
			gsl = 'winnersfirst'
		elseif String.endsWith(gsl:lower(), GSL_LOSERS) then
			gsl = 'losersfirst'
		end
		if String.startsWith(gsl:lower(), GSL_GF) then
			args['M6header'] = 'Grand Final'
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
	matchlistVars:delete('gsl')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
