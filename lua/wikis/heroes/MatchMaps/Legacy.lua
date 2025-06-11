---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')

local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local globalVars = PageVariableNamespace()

local UNKNOWN_MAP = 'Unknown'
local TBD = 'tbd'
local DEFAULT_WIN = 'W'
local FORFEIT = 'FF'
local MAX_NUMBER_OF_OPPONENTS = 2

local MatchMapsLegacy = {}

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return string
function MatchMapsLegacy.convertMap(frame)
	local args = Arguments.getArgs(frame)
	args.map = Table.extract(args, 'battleground') or UNKNOWN_MAP
	args.winner = Table.extract(args, 'win')
	return Json.stringify(args)
end

---@param args table
function MatchMapsLegacy._handleLocation(args)
	if Logic.isEmpty(args.location) then return end

	local matchStatus = Logic.readBool(args.finished) and 'was' or 'being'
	local locationComment = 'Match ' .. matchStatus .. ' played in ' .. Table.extract(args, 'location')
	args.comment = args.comment and (args.comment .. '<br>' .. locationComment) or locationComment
end

---@param args table
function MatchMapsLegacy._handleMaps(args)
	for key, jsonMap, mapIndex in Table.iter.pairsByPrefix(args, 'match') do
		local map = Json.parse(jsonMap) or {}
		map.vod = Table.extract(args, 'vodgame' .. mapIndex)
		args[key] = nil
		args['map' .. mapIndex] = Json.stringify(map)
	end
end

---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	MatchMapsLegacy._handleMaps(args)
	MatchMapsLegacy._handleLocation(args)

	return Json.stringify(args)
end

---@param args table
---@return table
function MatchMapsLegacy._mergeDetailsIntoArgs(args)
	local details = Json.parseIfTable(Table.extract(args, 'details')) or {}

	return Table.merge(details, args, {
		date = details.date or args.date,
		dateheader = Logic.isNotEmpty(args.date)
	})
end

---@param matchArgs table
function MatchMapsLegacy._readMaps(matchArgs)
	local getMapFromWinnerInput = function (mapWinner)
		return mapWinner and {
			map = UNKNOWN_MAP,
		} or nil
	end

	Array.mapIndexes(function (index)
		local mapWinner = Table.extract(matchArgs, 'map' .. index .. 'win')
		local map = Json.parseIfTable(matchArgs['map' .. index]) or getMapFromWinnerInput(mapWinner)
		if map and Logic.isEmpty(map.winner) then
			map.winner = mapWinner
		end
		matchArgs['map' .. index] = map
		return map
	end)
end

---@param matchArgs table
function MatchMapsLegacy._readOpponents(matchArgs)
	local walkover = tonumber(Table.extract(matchArgs, 'walkover'))

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function (opponentIndex)
		local template = string.lower(Logic.nilIfEmpty(Table.extract(matchArgs, 'team' .. opponentIndex)) or TBD)

		matchArgs['opponent' .. opponentIndex] = {
			template = template,
			type = template == TBD and Opponent.literal or Opponent.team,
			score = Logic.nilIfEmpty(Table.extract(matchArgs, 'games' .. opponentIndex)) or
				(walkover and walkover ~= 0 and (walkover == opponentIndex and DEFAULT_WIN or FORFEIT))
		}
	end)
end

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return string
function MatchMapsLegacy.convertMatch(frame)
	local matchArgs = MatchMapsLegacy._mergeDetailsIntoArgs(Arguments.getArgs(frame))
	MatchMapsLegacy._readMaps(matchArgs)
	MatchMapsLegacy._readOpponents(matchArgs)

	return Match.makeEncodedJson(matchArgs)
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
	local newArgs = {
		id = args.id,
		title = args.title,
		width = args.width,
		isLegacy = true,
		store = store,
		noDuplicateCheck = not store,
		collapsed = hide,
		attached = hide
	}

	globalVars:set('islegacy', 'true')
	for _, match, index in Table.iter.pairsByPrefix(args, 'match') do
		newArgs['M' .. index] = match
	end
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(newArgs)
end

return MatchMapsLegacy
