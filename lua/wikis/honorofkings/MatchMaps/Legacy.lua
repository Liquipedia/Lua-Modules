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

local globalVars = PageVariableNamespace()

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_MUMBER_OF_PLAYERS = 5
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'
local FORFEIT = 'FF'
local TBD = 'tbd'

local MatchMapsLegacy = {}

---@param args table
---@param details table
---@return table
function MatchMapsLegacy.copyDetailsToArgs(args, details)
	for key, value in pairs(details) do
		if Logic.isEmpty(args[key]) then
			args[key] = value
		end
	end
	args.details = nil
	return args
end

---@param args table
---@param details table
---@return table
function MatchMapsLegacy.setHeaderIfEmpty(args, details)
	args.header = args.header or args.date
	args.date = details.date or args.date
	return args
end

---@param args table
---@return table
function MatchMapsLegacy._handleMaps(args)
	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local map = Json.parse(matchJson) or {}
		local mapKey = 'map' .. matchIndex
		for key, value in pairs(map) do
			args[mapKey .. key] = value
		end
		args[mapKey .. 'winner'] = Table.extract(args, mapKey .. 'win')
		args[matchKey] = nil
	end
	return args
end

---@param args table
---@return table
function MatchMapsLegacy._handleLocation(args)
	if args.location then
		local matchStatus = Logic.readBool(args.finished) and 'was' or 'being'
		local locationComment = 'Match ' .. matchStatus .. ' played in ' .. args.location
		args.comment = args.comment and (args.comment .. '<br>' .. locationComment) or locationComment
		args.location = nil
	end
	return args
end

-- invoked by Template:BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args = MatchMapsLegacy._handleMaps(args)
	args = MatchMapsLegacy._handleLocation(args)
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
		local map = {
			map = Table.extract(details, prefix),
			winner = Table.extract(details, prefix .. 'winner') or args[prefix .. 'win'],
			length = Table.extract(details, prefix .. 'length'),
			vod = Table.extract(details, 'vodgame' .. index)
		}

		Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(oppIndex)
			local side = 'team' .. oppIndex .. 'side'
			map[side] = Table.extract(details, prefix .. side)

			Array.forEach(Array.range(1, MAX_MUMBER_OF_PLAYERS), function (playerIndex)
				local pick = 't' .. oppIndex .. 'h' .. playerIndex
				map[pick] = Table.extract(details, prefix .. pick)
				local ban = 't' .. oppIndex .. 'b' .. playerIndex
				map[ban] = Table.extract(details, prefix .. ban)
			end)
		end)
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
		return map
	end)

	return args, details
end

---@param args table
---@return table
function MatchMapsLegacy._handleOpponents(args)
	local walkover = tonumber(Table.extract(args, 'walkover'))

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(opponentIndex)
		local template = Table.extract(args, 'team' .. opponentIndex)

		if (not template) or template == '&nbsp;' then
			template = TBD
		else
			template = string.lower(template)
		end

		local score
		local winner = tonumber(args.winner)
		if walkover and walkover ~= 0 then
			score = walkover == opponentIndex and DEFAULT_WIN or FORFEIT
		elseif args['score' .. opponentIndex] then
			score = Table.extract(args, 'score' .. opponentIndex)
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
			}
		end
		args['opponent' .. opponentIndex] = opponent
	end)
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

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return string
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local details = Json.parseIfString(args.details or '{}')

	args, details = MatchMapsLegacy._handleDetails(args, details)
	args = MatchMapsLegacy._handleOpponents(args)
	args = MatchMapsLegacy._setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy._copyDetailsToArgs(args, details)

	return Json.stringify(args)
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

	local matchsection = Logic.nilOr(args.lpdb_title, args.title)
	if Logic.readBoolOrNil(matchsection) ~= false then
		args.matchsection = matchsection
	end
	globalVars:set('islegacy', 'true')

	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(matchJson) --[[@as table]]
		args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		args['M' .. matchIndex] = Json.stringify(match)
		args[matchKey] = nil
	end

	globalVars:delete('islegacy')

	args[1] = nil
	args.hide = nil
	args.lpdb_title = nil

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
