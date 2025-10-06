---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')

local Opponent = Lua.import('Module:Opponent/Custom')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 20
local TBD = 'tbd'
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'

local MatchMapsLegacy = {}

---@param frame Frame
function MatchMapsLegacy.init(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width)
	matchlistVars:set('hide', args.hide or 'true')
	matchlistVars:set('store', store and 'true' or nil)
end

---@param frame Frame
---@return string?
function MatchMapsLegacy.match(frame)
	local args = Arguments.getArgs(frame)
	local generate = Logic.readBool(Table.extract(args, 'generate'))

	local matchArgs = MatchMapsLegacy._mergeDetailsIntoArgs(args)
	MatchMapsLegacy._readMaps(matchArgs)
	MatchMapsLegacy._readOpponents(matchArgs)

	if generate then
		return Json.stringify(matchArgs)
	end

	Template.stashReturnValue(matchArgs, 'LegacyMatchlist')
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
	Array.forEach(Array.range(1, MAX_NUM_MAPS), function(mapIndex)
		local prefix = 'map' .. mapIndex
		local mapArgs = {
			map = Table.extract(matchArgs, prefix),
			winner = Table.extract(matchArgs, prefix .. 'win'),
			mode = Table.extract(matchArgs, prefix .. 'type'),
			vod = Table.extract(matchArgs, 'vodgame' .. mapIndex),
			score1 = Table.extract(matchArgs, prefix .. 'score1'),
			score2 = Table.extract(matchArgs, prefix .. 'score2'),
		}
		matchArgs[prefix] = Logic.nilIfEmpty(mapArgs)
	end)
end

---@param matchArgs table
function MatchMapsLegacy._readOpponents(matchArgs)
	local walkover = tonumber(Table.extract(matchArgs, 'walkover'))

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(opponentIndex)
		local template = string.lower(Logic.nilIfEmpty(Table.extract(matchArgs, 'team' .. opponentIndex)) or TBD)

		matchArgs['opponent' .. opponentIndex] = {
			template = template,
			type = template == TBD and Opponent.literal or Opponent.team,
			score = Logic.nilIfEmpty(Table.extract(matchArgs, 'games' .. opponentIndex)) or
				(walkover and walkover ~= 0 and (walkover == opponentIndex and DEFAULT_WIN or DEFAULT_LOSS))
		}
	end)
end

---@return string?
function MatchMapsLegacy.close()
	local bracketid = matchlistVars:get('bracketid')
	if Logic.isEmpty(bracketid) then return end

	local matchListArgs = {
		id = bracketid,
		title = matchlistVars:get('matchListTitle'),
		width = matchlistVars:get('width'),
		isLegacy = true,
	}

	local matches = Template.retrieveReturnValues('LegacyMatchlist') --[[@as table]]
	Array.forEach(matches, function(match, matchIndex)
		matchListArgs['M' .. matchIndex] = Match.makeEncodedJson(match)
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

	-- store matches
	local matchHtml = MatchGroup.MatchList(matchListArgs)

	MatchMapsLegacy._resetVars()

	return matchHtml
end

function MatchMapsLegacy._resetVars()
	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
end

--- for bot conversion to proper match2 matchlists
---@param frame Frame
---@return string
function MatchMapsLegacy.generate(frame)
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
		width = args.width,
		collapsed = Logic.readBoolOrNil(args.hide),
		attached = Logic.readBoolOrNil(args.hide),
		store = store,
		noDuplicateCheck = store == false or nil,
		patch = args.patch,
	}

	local matchsection = Logic.nilOr(args.lpdb_title, args.title)
	if Logic.readBoolOrNil(matchsection) ~= false then
		parsedArgs.matchsection = matchsection
	end

	---@type table[]
	local matches = Array.mapIndexes(function(index)
		return Json.parseIfTable(args[index + offset])
	end)

	Array.forEach(matches, function(match, matchIndex)
		parsedArgs['M' .. matchIndex] = Match.makeEncodedJson(match)
	end)

	return MatchGroupLegacy.generateWikiCodeForMatchList(parsedArgs)
end

return MatchMapsLegacy
