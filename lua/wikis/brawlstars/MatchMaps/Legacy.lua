---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local CharacterIcon = Lua.import('Module:CharacterIcon')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Json = Lua.import('Module:Json')
local MatchGroup = Lua.import('Module:MatchGroup')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local CharacterNames = Lua.import('Module:BrawlerNames', {loadData = true})

local MatchGroupBase = Lua.import('Module:MatchGroup/Base')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MAX_NUMBER_OF_OPPONENTS = 2
local DEFAULT_WIN = 'W'
local DEFAULT_LOSS = 'L'
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
		if Logic.isEmpty(map) then
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
		args[prefix .. 'winner'] = winner
		args[prefix .. 'maptype'] = Table.extract(args, prefix ..'type')

		return true
	end)

	return args
end

---@param args table
---@return table
function MatchMapsLegacy._handleBans(args)
	local bans = {}
	Array.mapIndexes(function (index)
		local ban = Table.extract(args, 'ban' .. (index == 1 and '' or index))
		if Logic.isEmpty(ban) then
			return false
		end
		table.insert(bans, CharacterIcon.Icon({
			character = CharacterNames[ban:lower()],
			size = '30px'
		}))
		return true
	end)

	if #bans == 0 then
		return args
	end

	local bansComment = '\'\'\'Bans\'\'\':' .. table.concat(bans, '&nbsp;')
	args.comment = args.comment and (args.comment .. '<br>' .. bansComment) or bansComment
	return args
end

-- invoked by Template:BracketMatchSummary
---@param frame Frame
---@return string
function MatchMapsLegacy.convertBracketMatchSummary(frame)
	local args = Arguments.getArgs(frame)
	args = MatchMapsLegacy._handleMaps(args)
	args = MatchMapsLegacy._handleBans(args)
	return Json.stringify(args)
end

---@param args table
---@param details table
---@return table, table
function MatchMapsLegacy._handleDetails(args, details)
	Array.mapIndexes(function (index)
		local prefix = 'map' .. index
		if not details[prefix] then
			return false
		end
		local map = {
			map = Table.extract(details, prefix),
			winner = Table.extract(details, prefix .. 'winner'),
			maptype = Table.extract(details, prefix .. 'maptype'),
			score1 = Table.extract(details, prefix .. 'score1'),
			score2 = Table.extract(details, prefix .. 'score2')
		}
		args[prefix] = map

		if map and map.winner then
			args.mapWinnersSet = true
		end

		return true
	end)

	return args, details
end

---@param args table
---@return table
function MatchMapsLegacy._getScoresFromMapWinners(args)
	local scores = {}
	local hasScores = false
	Array.mapIndexes(function (index)
		local winner = tonumber(Table.extract(args, 'map' .. index .. 'win'))
		if winner and winner > 0 and winner <= MAX_NUMBER_OF_OPPONENTS then
			scores[winner] = (scores[winner] or 0) + 1
			hasScores = true
			return true
		end
		return false
	end)
	if hasScores then
		scores[1] = scores[1] or 0
		scores[2] = scores[2] or 0
	end
	return scores
end

---@param args table
---@return table
function MatchMapsLegacy._handleOpponents(args)
	args.winner = args.winner or Table.extract(args, 'win')
	local walkover = tonumber(Table.extract(args, 'walkover'))
	local scores = MatchMapsLegacy._getScoresFromMapWinners(args)

	Array.forEach(Array.range(1, MAX_NUMBER_OF_OPPONENTS), function(opponentIndex)
		args['score' .. opponentIndex] = args['score' .. opponentIndex] or
			Table.extract(args, 'games' .. opponentIndex)
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
			if Logic.isNotEmpty(scores[opponentIndex]) then
				score = scores[opponentIndex]
			else
				score = winner == opponentIndex and DEFAULT_WIN or DEFAULT_LOSS
			end
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
		matchid = 'R1M1',
	})
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
	matchlistVars:set('hide', args.hide or 'true')
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width or '300px')
	matchlistVars:set('matchsection', args.matchsection)
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
	matchlistVars:delete('matchsection')
	globalVars:delete('islegacy')

	return MatchGroup.MatchList(args)
end

return MatchMapsLegacy
