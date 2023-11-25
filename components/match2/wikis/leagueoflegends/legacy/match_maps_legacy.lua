---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local MatchMapsLegacy = {}

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Json = require('Module:Json')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Template = require('Module:Template')

local MatchSubobjects = Lua.import('Module:Match/Subobjects', { requireDevIfEnabled = true })

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_MAPS = 9
local MAX_NUMBER_OF_MATCHES = 30
local DUMMY_MAP_NAME = 'null'
local DEFAULT = 'default'
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'

---@param args table
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
			template = 'tbd'
		else
			template = string.lower(template)
		end
		local score
		if args.walkover then
			if tonumber(args.walkover) ~= 0 then
				score = tonumber(args.walkover) == index and DEFAULT_WIN or DEFAULT_LOSS
			end
		else
			score = tonumber(args['score' .. index])
		end

		args['opponent' .. index] = {
			score = score,
			template = template,
			type = 'team',
		}

		args['team' .. index] = nil
		args.walkover = nil
		args['score' .. index] = nil
	end

	return args
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy.convertMaps(args, details)
	for index = 1, MAX_NUMBER_OF_MAPS do
		if details['match' .. index] then
			-- match corresponds to MatchLua
			local match = Json.parseIfString(details['match' .. index] or '{}')
			if Logic.isEmpty(match.win) then
				match.win = args['map' .. index .. 'win']
			end
			match.winner = match.win
			match.win = nil

			if match.length and match.length:lower() == DEFAULT then
				match.walkover = match.winner
			end

			match.map = DUMMY_MAP_NAME
			local map = MatchSubobjects.luaGetMap(match)
			map.map = nil
			args['map' .. index] = map

			args['map' .. index .. 'win'] = nil
			details['match' .. index] = nil
		elseif args['map' .. index .. 'win'] then
			local map = MatchSubobjects.luaGetMap{
				winner = args['map' .. index .. 'win'],
				map = DUMMY_MAP_NAME
			}
			map.map = nil
			args['map' .. index] = map

			args['map' .. index .. 'win'] = nil
		else
			break
		end
	end
	return args, details
end

-- invoked by Template:MatchMapsLua
---@param frame Frame
---@return string?
function MatchMapsLegacy.convertMatch(frame)
	local args = Arguments.getArgs(frame)
	local details = Json.parseIfString(args.details or '{}')

	args = MatchMapsLegacy.convertOpponents(args)
	args, details = MatchMapsLegacy.convertMaps(args, details)

	args = MatchMapsLegacy.setHeaderIfEmpty(args, details)
	args = MatchMapsLegacy.copyDetailsToArgs(args, details)

	if Logic.readBool(matchlistVars:get('isOldMatchList')) then
		return Json.stringify(args)
	else
		Template.stashReturnValue(args, 'LegacyMatchlist')
	end
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

	matchlistVars:set('isOldMatchList', 'true')
	globalVars:set('islegacy', 'true')

	for matchIndex = 1, MAX_NUMBER_OF_MATCHES do
		if args['match' .. matchIndex] then
			local match = Json.parse(args['match' .. matchIndex])
			args['M' .. matchIndex .. 'header'] = match.header
			match.header = nil
			args['M' .. matchIndex] = Json.stringify(match)
			args['match' .. matchIndex] = nil
		else
			break
		end
	end

	matchlistVars:delete('isOldMatchList')
	globalVars:delete('islegacy')

	args[1] = nil
	args.hide = nil
	args.lpdb_title = nil

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

	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
