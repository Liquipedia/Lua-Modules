---
-- @Liquipedia
-- page=Module:LegacyMatchMaps
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--converts the old matchlists to be readable by the match2 system

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Template = require('Module:Template')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 20
local TBD = 'TBD'
local BYE = 'BYE'

local LegacyMatchMaps = {}

-- invoked by Template:MatchList
---@param frame Frame
---@return string
function LegacyMatchMaps.solo(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	local parsedArgs = {
		id = args.id,
		isLegacy = true,
		title = args.title,
		width = args.width,
		collapsed = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		attached = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		store = store,
		noDuplicateCheck = not store,
	}

	for _, matchInput, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		parsedArgs['M' .. matchIndex] = LegacyMatchMaps._readSoloMatch(matchInput)
	end

	-- generate Display
	-- this also stores the MatchData
	return MatchGroup.MatchList(parsedArgs)
end

---@param matchInput table
---@return string?
function LegacyMatchMaps._readSoloMatch(matchInput)
	local args = Json.parseIfTable(matchInput)
	if not args then return end

	local details = Json.parseIfTable(args.details) or args.details or {}
	args = Table.merge(details, args)

	if args.date then
		args.dateheader = true
	end

	LegacyMatchMaps._readSoloOpponents(args)
	LegacyMatchMaps._readMaps(args)

	return Match.makeEncodedJson(args)
end

---@param args table
function LegacyMatchMaps._readSoloOpponents(args)
	Array.forEach(Array.range(1, NUMBER_OF_OPPONENTS), function(opponentIndex)
		local prefix = 'p' .. opponentIndex
		local name = args[prefix] or TBD
		args[prefix] = nil
		if name:upper() == BYE then
			args['opponent' .. opponentIndex] = {type = Opponent.literal, name = BYE}
			return
		end

		args['opponent' .. opponentIndex] = {
			type = Opponent.solo,
			p1 = name,
			p1flag = args[prefix .. 'flag'],
			p1link = args[prefix .. 'link'],
			p1race = args[prefix .. 'race'],
			score = args[prefix .. 'score'],
		}

		args[prefix .. 'flag'] = nil
		args[prefix .. 'link'] = nil
		args[prefix .. 'race'] = nil
		args[prefix .. 'score'] = nil
	end)
end

---@param args table
function LegacyMatchMaps._readMaps(args)
	local toNewKey = function(prefix, key)
		local index, newKeyPrefix = string.match(key, '^' .. prefix .. 'p(%d)(%l+)$')
		if index and newKeyPrefix then
			return newKeyPrefix .. index
		end
		return string.gsub(key, '^' .. prefix, '')
	end

	for mapIndex = 1, MAX_NUM_MAPS do
		local prefix = 'map' .. mapIndex
		local map = Table.filterByKey(args, function(key)
			return key == prefix or string.find(key, '^' .. prefix .. '[^%d]') ~= nil
		end)
		map = Table.map(map, function(key, value)
			args[key] = nil

			local noCheckIndex = string.match(key, '^' .. prefix .. 'p(%d)heroesNoCheck$')
			if noCheckIndex then
				--2v2 submatches never had heroes data so no check needed for those
				return 't' .. noCheckIndex .. 'p1heroesNoCheck', value
			end

			if key == prefix then
				return 'map', value
			end

			if key == prefix .. 'win' then
				return 'winner', value
			end

			return toNewKey(prefix, key), value
		end)
		map.vod = args['vodgame' .. mapIndex]
		args['vodgame' .. mapIndex] = nil
		args[prefix .. 'finished'] = true

		if Table.isNotEmpty(map) then
			args[prefix] = map
		end
	end
end

-- invoked by Template:MatchListStart
---@param frame Frame
function LegacyMatchMaps.teamInit(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '350px')
	matchlistVars:set('hide', args.hide or 'true')
	globalVars:set('islegacy', 'true')
end

-- invoked by Template:MatchMapsTeams
---@param frame Frame
function LegacyMatchMaps.teamMatch(frame)
	local args = Arguments.getArgs(frame)

	args = Table.merge(Json.parseIfString(args.details) or {}, args)
	args.details = nil

	LegacyMatchMaps._readTeamOpponents(args)
	--map data gets preprocessed already due to using the same template as in brackets
	LegacyMatchMaps._readMaps(args)

	Template.stashReturnValue(args, 'LegacyMatchlist')
end

---@param args table
function LegacyMatchMaps._readTeamOpponents(args)
	Array.forEach(Array.range(1, NUMBER_OF_OPPONENTS), function(opponentIndex)
		local template = args['team' .. opponentIndex]
		args['team' .. opponentIndex] = nil
		if not template then
			args['opponent' .. opponentIndex] = Opponent.blank(Opponent.literal)
			return
		elseif template:upper() == BYE then
			args['opponent' .. opponentIndex] = {type = Opponent.literal, name = BYE}
			return
		end

		args['opponent' .. opponentIndex] = {
			type = Opponent.team,
			template = template,
			score = args['games' .. opponentIndex],
		}

		args['games' .. opponentIndex] = nil
	end)
end

-- invoked by Template:MatchListEnd
---@return string
function LegacyMatchMaps.teamClose()
	local bracketId = matchlistVars:get('bracketid')
	assert(bracketId, 'Missing id')

	local store = Logic.readBool(matchlistVars:get('store'))
	local hide = Logic.readBool(matchlistVars:get('hide'))

	local args = {
		id = bracketId,
		isLegacy = true,
		title = matchlistVars:get('matchListTitle'),
		width = matchlistVars:get('width'),
		store = store,
		noDuplicateCheck = not store,
		collapsed = hide,
		attached = hide,
	}

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	Array.forEach(matches, function(match, matchIndex)
		args['M' .. matchIndex] = Match.makeEncodedJson(match)
	end)

	-- generate Display
	-- this also stores the MatchData
	local matchHtml = MatchGroup.MatchList(args)

	LegacyMatchMaps._resetVars()

	return matchHtml
end

function LegacyMatchMaps._resetVars()
	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	globalVars:delete('islegacy')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
end

return LegacyMatchMaps
