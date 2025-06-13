---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchMapsLegacy = {}

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Template = require('Module:Template')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_MUMBER_OF_PLAYERS = 5
local DEFAULT = 'default'
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'
local FORFEIT = 'FF'
local TBD = 'tbd'

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
function MatchMapsLegacy.convertOpponents(args)
	for index = 1, MAX_NUMBER_OF_OPPONENTS do
		local template = args['team' .. index]
		if (not template) or template == '&nbsp;' then
			template = TBD
		else
			template = string.lower(template)
		end
		local score
		local winner = tonumber(args.winner)
		if args.walkover then
			if tonumber(args.walkover) ~= 0 then
				score = tonumber(args.walkover) == index and DEFAULT_WIN or FORFEIT
			end
		elseif args['score' .. index] then
			score = tonumber(args['score' .. index])
		elseif not args.mapWinnersSet and winner then
			score = winner == index and DEFAULT_WIN or DEFAULT_LOSS
		end

		if template ~= TBD then
			args['opponent' .. index] = {
				score = score,
				template = template,
				type = 'team',
			}
		end
		args['opponent' .. index .. 'literal'] = args['team' .. index .. 'wildrift']

		args['team' .. index] = nil
		args['score' .. index] = nil
	end
	args.walkover = nil
	args.mapWinnersSet = nil

	return args
end

---@param args table
---@return table
function MatchMapsLegacy.handleLiteralsForOpponents(args)
	for index = 1, MAX_NUMBER_OF_OPPONENTS do
		if Logic.isEmpty(args['opponent' .. index]) then
			args['opponent' .. index] = {
				['type'] = 'literal', template = 'tbd', name = args['opponent' .. index .. 'literal']
			}
		end
	end
	return args
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy.handleDetails(args, details)
	local getMapFromDetails = function (index)
		local prefix = 'map' .. index
		if not details[prefix] then
			return nil
		end
		local map = {}
		map.map = details[prefix]
		map.winner = details[prefix .. 'winner']
		--Try to get winner from "MatchMaps"
		if Logic.isEmpty(map.winner) then
			map.winner = args[prefix .. 'win']
		end

		if details[prefix .. 'length'] and details[prefix .. 'length']:lower() == DEFAULT then
			map.walkover = map.winner
		end
		map.length = details[prefix .. 'length']
		map.vod = details[prefix .. 'vod']

		for oppIndex = 1, MAX_NUMBER_OF_OPPONENTS do
			local side = 'team' .. oppIndex .. 'side'
			map[side] = details[prefix .. side]
			details[prefix .. side] = nil
			for playerIndex = 1, MAX_MUMBER_OF_PLAYERS do
				local pick = 't' .. oppIndex .. 'c' .. playerIndex
				local ban = 't' .. oppIndex .. 'b' .. playerIndex
				map[pick] = details[prefix .. pick]
				map[ban] = details[prefix .. ban]
				details[prefix .. pick] = nil
				details[prefix .. ban] = nil
			end
		end
		details[prefix] = nil
		details[prefix .. 'winner'] = nil
		details[prefix .. 'length'] = nil
		details[prefix .. 'vod'] = nil
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
function MatchMapsLegacy.handleLocation(args)
	if args.location then
		local matchStatus = Logic.readBool(args.finished) and 'was' or 'being'
		local locationComment = 'Match ' .. matchStatus .. ' played in ' .. args.location
		args.comment = args.comment and (args.comment .. '<br>' .. locationComment) or locationComment
		args.location = nil
	end
	return args
end

---@param args table
---@return table
function MatchMapsLegacy.convertMaps(args)
	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local map = Json.parse(matchJson) or {}
		map.winner = map.win
		map.win = nil
		map.vod = args['vodgame' .. matchIndex]
		local mapKey = 'map' .. matchIndex
		for key, value in pairs(map) do
			args[mapKey .. key] = value
		end
		args['vodgame' .. matchIndex] = nil
		args[matchKey] = nil
	end
	return args
end

-- invoked by Template:BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args = MatchMapsLegacy.handleLocation(args)
	args = MatchMapsLegacy.convertMaps(args)
	return Json.stringify(args)
end

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return Html
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local details = Json.parseIfString(args.details or '{}')

	args, details = MatchMapsLegacy.handleDetails(args, details)
	args = MatchMapsLegacy.convertOpponents(args)
	args = MatchMapsLegacy.handleLiteralsForOpponents(args)
	args = MatchMapsLegacy.setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy.copyDetailsToArgs(args, details)

	Template.stashReturnValue(args, 'LegacyMatchlist')
	return mw.html.create('div'):css('display', 'none')
end

-- invoked by Template:MatchListStart
---@param frame Frame
function MatchMapsLegacy.matchListStart(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)
	local matchsection = Logic.nilOr(args.lpdb_title, args.title)
	if Logic.readBoolOrNil(matchsection) ~= false then
		matchlistVars:set('matchsection', matchsection)
	end

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '300px')
	matchlistVars:set('hide', args.hide or 'true')
	matchlistVars:set('patch', args.patch)
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
		patch = matchlistVars:get('patch')
	}

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	Array.forEach(matches, function(match, matchIndex)
		args['M' .. matchIndex .. 'header'] = match.header
		match.header = nil
		args['M' .. matchIndex] = Json.stringify(match)
	end)

	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('width')
	matchlistVars:delete('hide')
	matchlistVars:delete('patch')
	matchlistVars:delete('matchsection')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
