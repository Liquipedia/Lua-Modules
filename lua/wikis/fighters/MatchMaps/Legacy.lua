---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchMapsLegacy = {}

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Json = Lua.import('Module:Json')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local Opponent = Lua.import('Module:Opponent/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
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
	args.date = details.date or args.date
	return args
end

---@param args table
---@return table
function MatchMapsLegacy.convertOpponents(args)
	for index = 1, MAX_NUMBER_OF_OPPONENTS do
		local player = Table.extract(args, 'p' .. index)
		local playerLink = player
		if Logic.isNotEmpty(args['p' .. index .. 'display']) then
			player = Table.extract(args, 'p' .. index .. 'display')
		else
			playerLink = nil
		end
		local score
		local winner = tonumber(args.win)
		if args.walkover then
			if tonumber(args.walkover) ~= 0 then
				score = tonumber(args.walkover) == index and DEFAULT_WIN or FORFEIT
			end
		elseif args['p' .. index .. 'score'] then
			score = tonumber(Table.extract(args, 'p' .. index .. 'score'))
		elseif not args.mapWinnersSet and Logic.isEmpty(args.map1) and winner then
			score = winner == index and DEFAULT_WIN or DEFAULT_LOSS
		end

		if string.lower(player or '') ~= TBD then
			args['opponent' .. index] = {
				score = score,
				p1 = player,
				p1link = Logic.emptyOr(playerLink, player),
				p1flag = Table.extract(args, 'p' .. index .. 'flag'),
				type = Opponent.solo,
			}
		end
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
				['type'] = Opponent.literal, name = args['opponent' .. index .. 'literal']
			}
		end
	end
	return args
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy.handleDetails(args, details)
	---@param index integer
	---@return table?
	local getMapFromDetails = function (index)
		local map = {
			winner = Table.extract(args, 'win' .. index)
		}

		for oppIndex = 1, MAX_NUMBER_OF_OPPONENTS do
			local opponentPrefix = 'p' .. oppIndex
			local characters = Array.parseCommaSeparatedString(Table.extract(args, opponentPrefix .. 'char' .. index))
			if Logic.isNotEmpty(characters) then
				map['o' .. oppIndex .. 'p1'] = Json.stringify(characters)
			end
			map['score' .. oppIndex] = Table.extract(args, opponentPrefix .. 'score' .. index)
		end

		return Logic.nilIfEmpty(map)
	end

	local maps = Array.mapIndexes(getMapFromDetails)

	Array.forEach(maps, function (map, mapIndex)
		args['map' .. mapIndex] = map
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
	args = MatchMapsLegacy.handleLocation(args)
	args = MatchMapsLegacy.convertMaps(args)
	return Json.stringify(args)
end

-- invoked by Template:Match stages
---@param frame Frame
---@return string|Html
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local generate = Logic.readBool(Table.extract(args, 'generate'))
	local details = Json.parseIfString(args.details or '{}')

	args, details = MatchMapsLegacy.handleDetails(args, details)
	args = MatchMapsLegacy.convertOpponents(args)
	args = MatchMapsLegacy.handleLiteralsForOpponents(args)
	args = MatchMapsLegacy.setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy.copyDetailsToArgs(args, details)

	if generate or Logic.readBool(matchlistVars:get('isOldMatchList')) then
		return Json.stringify(args)
	else
		Template.stashReturnValue(args, 'LegacyMatchlist')
		return mw.html.create('div'):css('display', 'none')
	end
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
		noDuplicateCheck = not store or nil,
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

--- for bot conversion to proper match2 matchlists
---@param frame Frame
---@return string
function MatchMapsLegacy.generate(frame)
	return MatchMapsLegacy.matchList(frame, true)
end

--- for bot conversion to proper match2 matchlists
---@param frame Frame
---@return string
function MatchMapsLegacy.generate2(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.readBoolOrNil(args.store)

	local offset = 0
	local title = args.title
	if not title and not Json.parseIfTable(args[1]) then
		title = args[1]
		offset = 1
	end

	local parsedArgs = {
		id = args.id,
		title = title,
		width = args.width or '300px',
		collapsed = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		attached = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		store = store,
	}

	local matchsection = Logic.nilOr(args.lpdb_title, args.title)
	if Logic.readBoolOrNil(matchsection) ~= false then
		parsedArgs.matchsection = matchsection
	end

	---@type table[]
	local matches = Array.mapIndexes(function(index)
		return args[index + offset]
	end)

	Array.forEach(matches, function(match, matchIndex)
		parsedArgs['M' .. matchIndex] = match
	end)

	return MatchGroupLegacy.generateWikiCodeForMatchList(parsedArgs)
end

return MatchMapsLegacy
