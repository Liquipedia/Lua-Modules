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
local MatchGroup = Lua.import('Module:MatchGroup')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')

local MapToMode = Lua.import('Module:MapToMode', {loadData = true})

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
local DEFAULT_WIN = 'W'
local FORFEIT = 'FF'
local TBD = 'tbd'

local MatchMapsLegacy = {}

---@param args table
---@return table
function MatchMapsLegacy._handleMaps(args)
	Array.mapIndexes(function (index)
		local prefix = 'map' .. index
		local map = args[prefix]
		local winner = Table.extract(args, prefix .. 'win')
		if Logic.isEmpty(map) and Logic.isEmpty(winner) then
			return false
		end
		local score = Table.extract(args, prefix .. 'score')
		local score1
		local score2
		if Logic.isNotEmpty(score) then
			local splitedScore = mw.text.split(score, '-')
			score1 = splitedScore[1]
			score2 = splitedScore[2]
		end

		args[prefix .. 'score1'] = mw.text.trim(score1 or '')
		args[prefix .. 'score2'] = mw.text.trim(score2 or '')
		args[prefix .. 'mode'] = MapToMode[map and map:lower()] or ''
		args[prefix .. 'winner'] = winner
		args[prefix .. 'vod'] = Table.extract(args, 'vodgame' .. index)

		return true
	end)

	return args
end

--Used when Match/Old
---@param args table
---@return table
function MatchMapsLegacy._handleJsonMaps(args)
	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local map = Json.parse(matchJson) or {}
		local prefix = 'map' .. matchIndex
		args[prefix] = map.map
		args[prefix .. 'mode'] = MapToMode[map.map and map.map:lower()] or ''
		args[prefix .. 'winner'] = map.win
		args[prefix .. 'vod'] = Table.extract(args, 'vodgame' .. matchIndex)

		args[matchKey] = nil
	end
	return args
end

-- invoked by Template:BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	if Logic.isEmpty(args.match1) then
		args = MatchMapsLegacy._handleMaps(args)
	else
		args = MatchMapsLegacy._handleJsonMaps(args)
	end

	return Json.stringify(args)
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy._handleDetails(args, details)
	Array.mapIndexes(function (index)
		local prefix = 'map' .. index
		if not details[prefix] then
			return nil
		end
		local map = {
			map = Table.extract(details, prefix),
			score1 = Table.extract(details, prefix .. 'score1'),
			score2 = Table.extract(details, prefix .. 'score2'),
			mode = Table.extract(details, prefix .. 'mode'),
			winner = Table.extract(details, prefix .. 'winner'),
			vod = Table.extract(details, prefix .. 'vod'),
		}
		args['map' .. index] = map
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

		local score = Table.extract(args, 'games' .. opponentIndex) or Table.extract(args, 'score' .. opponentIndex)
		if walkover and walkover ~= 0 then
			score = walkover == opponentIndex and DEFAULT_WIN or FORFEIT
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
				template = TBD
			}
		end

		args['opponent' .. opponentIndex] = opponent
	end)
	args.winner = args.winner or Table.extract(args, 'win')

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

	local matchsection = Logic.nilOr(args.lpdb_title, args.title)
	if Logic.readBoolOrNil(matchsection) ~= false then
		args.matchsection = matchsection
	end
	matchlistVars:set('isOldMatchList', 'true')
	globalVars:set('islegacy', 'true')

	for matchKey, matchJson, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		local match = Json.parse(matchJson) --[[@as table]]
		args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		args['M' .. matchIndex] = Json.stringify(match)
		args[matchKey] = nil
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

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '300px')
	matchlistVars:set('hide', args.hide or 'true')
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
	}

	local matches = Template.retrieveReturnValues('LegacyMatchlist')

	Array.forEach(matches, function(match, matchIndex)
		args['M' .. matchIndex .. 'header'] = Table.extract(match, 'header')
		args['M' .. matchIndex] = Json.stringify(match)
	end)

	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('width')
	matchlistVars:delete('hide')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
