---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')


local MatchMapsLegacy = {}

local NUMBER_OF_OPPONENTS = 2

-- invoked by Template:LegacyMatchList
function MatchMapsLegacy.matchlist(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacy._matchlist(args)
end

function MatchMapsLegacy._matchlist(args)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
	)

	local bracketId = args.id
	-- since the same template is also used for old team match lists
	-- that are not yet converted we need to return an empty string
	-- in case we have no bracketId
	if String.isEmpty(bracketId) then
		return ''
	end

	local matches = {}

	local matchIndex = 1
	local inputIndex = 1
	local match = Json.parseIfString(args['match' .. inputIndex])
	while match do
		if Table.isEmpty(match) then
			-- catch some old bs where they put headers inside matches with tr and td stuff ...
			local header = string.match(args['match' .. inputIndex], '<tr.-> ?<td.->(.-)</td')
			matches['M' .. matchIndex .. 'header'] = header
		else
			matches['M' .. matchIndex] = Match.makeEncodedJson(match)
			matchIndex = matchIndex + 1
		end

		inputIndex = inputIndex + 1
		match = Json.parseIfString(args['match' .. inputIndex])
	end

	matches.id = bracketId
	matches.isLegacy = true
	matches.title = Logic.emptyOr(args.title, args[1], 'Match List')
	matches.width = args.width
	local hide = Logic.readBool(Logic.emptyOr(args.hide, true))
	if hide then
		matches.collapsed = true
		matches.attached = true
	else
		matches.collapsed = false
	end
	if Logic.readBool(store) then
		matches.store = true
	else
		matches.noDuplicateCheck = true
		matches.store = false
	end

	-- generate Display
	-- this also stores the MatchData
	local matchListHtml = MatchGroup.MatchList(matches)

	MatchMapsLegacy._resetVars()

	return matchListHtml
end

function MatchMapsLegacy._resetVars()
	Variables.varDefine('match2bracketindex', Variables.varDefault('match2bracketindex', 0) + 1)
	Variables.varDefine('match_number', 0)
	Variables.varDefine('matchsection', '')
end


-- invoked by Template:MatchMaps/Legacy or Template:MatchMaps/Legacy2v2
function MatchMapsLegacy.preprocess(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacy._preProcess(args)
end

function MatchMapsLegacy._preProcess(match)
	for opponentIndex = 1, NUMBER_OF_OPPONENTS do
		if match.type == '2v2' then
			MatchMapsLegacy._handle2v2Opponent(match, opponentIndex)
		else
			MatchMapsLegacy._handleOpponent(match, opponentIndex)
		end
	end
	MatchMapsLegacy._handleMaps(match)

	if match.date then
		match.dateheader = true
	end

	-- all other args from the match maps calls are just passed along directly
	-- as they can be read by the match2 processing

	return Json.stringify(match)
end

function MatchMapsLegacy._handleOpponent(match, opponentIndex)
	if match['player' .. opponentIndex] and match['player' .. opponentIndex]:lower() == 'bye' then
		match['opponent' .. opponentIndex] = {
			['type'] = 'literal',
			name = 'BYE',
		}
	else
		match['opponent' .. opponentIndex] = {
			['type'] = 'solo',
			name = match['player' .. opponentIndex],
			link = match['playerlink' .. opponentIndex],
			race = match['player' .. opponentIndex .. 'race'],
			flag = match['player' .. opponentIndex .. 'flag'],
			score = match['p' .. opponentIndex .. 'score'],
		}
		if String.isEmpty(match['player' .. opponentIndex]) then
			match['opponent' .. opponentIndex]['type'] = 'literal'
		end
	end

	match['player' .. opponentIndex] = nil
	match['playerlink' .. opponentIndex] = nil
	match['player' .. opponentIndex .. 'race'] = nil
	match['player' .. opponentIndex .. 'flag'] = nil
	match['p' .. opponentIndex .. 'score'] = nil
end

--todo
function MatchMapsLegacy._handle2v2Opponent(match, opponentIndex)
	local opponent = {
		['type'] = 'duo',
		score = match['p' .. opponentIndex .. 'score'],
	}
	match['p' .. opponentIndex .. 'score'] = nil

	for runIndex = 1, 2 do
		local playerIndex = opponentIndex + (runIndex - 1) * 2
		if match['player' .. playerIndex] and match['player' .. playerIndex]:lower() == 'bye' then
			opponent = {
				['type'] = 'literal',
				name = 'BYE',
			}
			break
		end

		opponent['p' .. runIndex] = match['player' .. playerIndex]
		opponent['p' .. runIndex .. 'link'] = match['playerlink' .. playerIndex]
		opponent['p' .. runIndex .. 'race'] = match['player' .. playerIndex .. 'race']
		opponent['p' .. runIndex .. 'flag'] = match['player' .. playerIndex .. 'flag']

		match['player' .. playerIndex] = nil
		match['playerlink' .. playerIndex] = nil
		match['player' .. playerIndex .. 'race'] = nil
		match['player' .. playerIndex .. 'flag'] = nil
	end

	match['opponent' .. opponentIndex] = opponent
end

function MatchMapsLegacy._handleMaps(match)
	local gameIndex = 1
	local map = match['map' .. gameIndex]
	local mapWinner = match['map' .. gameIndex .. 'win']

	while map or mapWinner do
		match['map' .. gameIndex] = {
			map = map or 'unknown',
			winner = match['map' .. gameIndex .. 'win'],
			race1 = match['map' .. gameIndex .. 'p1race'],
			race2 = match['map' .. gameIndex .. 'p2race'],
			vod = match['vodgame' .. gameIndex],
		}

		match['map' .. gameIndex .. 'win'] = nil
		match['map' .. gameIndex .. 'p1race'] = nil
		match['map' .. gameIndex .. 'p2race'] = nil

		gameIndex = gameIndex + 1
		map = match['map' .. gameIndex]
		mapWinner = match['map' .. gameIndex .. 'win']
	end
end

return MatchMapsLegacy
