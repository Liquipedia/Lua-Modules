---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Faction = require('Module:Faction')
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')
local Streams = Lua.import('Module:Links/Stream')

local CustomMatchGroupInput = {}
local MapFunctions = {}

local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	assert(not Logic.readBool(match.ffa), 'FFA is not yet supported in AoE match2.')
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))
	match.game, match.mapsInfo = CustomMatchGroupInput._getMapsAndGame(match)

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return CustomMatchGroupInput.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)

	local games = CustomMatchGroupInput.extractMaps(match, opponents)
	match.links = MatchGroupInputUtil.getLinks(match)
	match.links.headtohead = CustomMatchGroupInput.getHeadToHeadLink(match, opponents)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and CustomMatchGroupInput.calculateMatchScore(games)
		or nil

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)
	match.bestof = CustomMatchGroupInput.getBestOf(match.bestof)

	local winnerInput = match.winner --[[@as string?]]
	local finishedInput = match.finished --[[@as string?]]
	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
		match.winner = MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	match.mode = Opponent.toLegacyMode(opponents[1].type, opponents[2].type)
	match.stream = Streams.processStreams(match)

	match.games = games
	match.opponents = opponents

	match.extradata = CustomMatchGroupInput._getExtraData(match)

	return match
end

---@param match table
---@param opponentIndex integer
---@param options readOpponentOptions
---@return table?
function CustomMatchGroupInput.readOpponent(match, opponentIndex, options)
	options = options or {}
	local opponentInput = Json.parseIfString(Table.extract(match, 'opponent' .. opponentIndex))
	if not opponentInput then
		return opponentIndex <= 2 and MatchGroupInputUtil.mergeRecordWithOpponent({}, Opponent.blank()) or nil
	end

	--- or Opponent.blank() is only needed because readOpponentArg can return nil for team opponents
	local opponent = Opponent.readOpponentArgs(opponentInput) or Opponent.blank()
	if Opponent.isBye(opponent) then
		local byeOpponent = Opponent.blank()
		byeOpponent.name = 'BYE'
		return MatchGroupInputUtil.mergeRecordWithOpponent({}, byeOpponent)
	end

	---@type number|string?
	local resolveDate = match.timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if resolveDate == DateExt.defaultTimestamp then
		resolveDate = DateExt.getContextualDate()
	end

	Opponent.resolve(opponent, resolveDate, {syncPlayer = true})

	local substitutions
	if opponent.type == Opponent.team then
		local manualPlayersInput = MatchGroupInputUtil.extractManualPlayersInput(match, opponentIndex, opponentInput)
		substitutions = manualPlayersInput.substitutions
		-- Change compared to commons MatchGroupInputUtil.readOpponent
		local template = mw.ext.TeamTemplate.raw(opponent.template or '') or {}
		opponent.players = MatchGroupInputUtil.readPlayersOfTeam(
			template.page or '',
			manualPlayersInput,
			options,
			{timestamp = match.timestamp, timezoneOffset = match.timezoneOffset}
		)
	end

	Array.forEach(opponent.players or {}, function(player)
		player.pageName = Page.pageifyLink(player.pageName)
	end)

	local record = MatchGroupInputUtil.mergeRecordWithOpponent(opponentInput, opponent, substitutions)

	-- no need to pagify non opponent names as for literals it is irrelevant
	-- and for party opponents it comes down to pagifying player names
	if options.pagifyTeamNames and opponent.type == Opponent.team then
		record.name = Page.pageifyLink(record.name)
	end

	return record
end

---@param match table
---@param opponents table[]
---@return table[]
function CustomMatchGroupInput.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if map.map == nil and map.winner == nil then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(match, map, opponents)
		map.map, map.extradata.displayname = CustomMatchGroupInput._getMapName(map, match.mapsInfo)
		map.extradata.mapmode = Table.extract(map, 'mode')

		Table.mergeInto(map, MatchGroupInputUtil.getTournamentContext(map, match))

		map.finished = MatchGroupInputUtil.mapIsFinished(map)
		map.opponents = Array.map(opponents, function(opponent, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, CustomMatchGroupInput.calculateMapScore(map.winner, map.finished))
			local players = CustomMatchGroupInput.getPlayersOfMapOpponent(map, opponent, opponentIndex)
			return {score = score, status = status, players = players}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param bestofInput string|integer?
---@return integer?
function CustomMatchGroupInput.getBestOf(bestofInput)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('bestof'))

	if bestof then
		Variables.varDefine('bestof', bestof)
	end

	return bestof
end

---@param match table
---@return string?, table?
function CustomMatchGroupInput._getMapsAndGame(match)
	local mapsInfo = Json.parseIfString(Variables.varDefault('tournament_maps'))

	if Logic.isNotEmpty(mapsInfo) and match.game then
		return match.game, mapsInfo
	end

	-- likely in section preview, fetch from LPDB
	local title = mw.title.getCurrentTitle()
	local pages = {
		title.text:gsub(' ', '_'),
		title.baseText:gsub(' ', '_'),
		title.rootText:gsub(' ', '_'),
	}
	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = table.concat(Array.map(pages, function(page) return '[[pagename::' .. page .. ']]' end), ' OR '),
			query = 'game, maps',
			order = 'pagename desc'
		})[1] or {}

	-- Store fetched data for following matches
	Variables.varDefine('tournament_game', data.game)
	Variables.varDefine('tournament_maps', data.maps)

	return match.game or data.game, Logic.emptyOr(mapsInfo, (Json.parse(data.maps)))
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer
function CustomMatchGroupInput.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@return table
function CustomMatchGroupInput._getExtraData(match)
	return {
		casters = MatchGroupInputUtil.readCasters(match, {noSort = true}),
	}
end

---@param match table
---@param opponents table[]
---@return string?
function CustomMatchGroupInput.getHeadToHeadLink(match, opponents)
	if opponents[1].type ~= Opponent.solo or opponents[2].type ~= Opponent.solo then
		return
	end
	if not Logic.readBool(Logic.emptyOr(match.headtohead, Variables.varDefault('tournament_headtohead'))) then
		return nil
	end
	if Opponent.isEmpty(opponents[1]) or Opponent.isEmpty(opponents[2]) then
		return nil
	end

	local player1, player2 =
		string.gsub(opponents[1].name, ' ', '_'),
		string.gsub(opponents[2].name, ' ', '_')

	return tostring(mw.uri.fullUrl('Special:RunQuery/Match_history')) ..
		'?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D=' ..player1 ..
		'&Head_to_head_query%5Bopponent%5D=' .. player2 .. '&wpRunQuery=Run+query'
end

---@param map table
---@param mapsInfo {name: string, link: string}[]?
---@return string?
---@return string?
function CustomMatchGroupInput._getMapName(map, mapsInfo)
	if String.isEmpty(map.map) or map.map == 'TBD' then
		return
	end
	if Logic.isEmpty(mapsInfo) then
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or ''), map.map
	end
	---@cast mapsInfo -nil
	local info = Array.find(mapsInfo, function(m)
		return m.name == map.map or m.link == map.map
	end)
	if not info then
		mw.ext.TeamLiquidIntegration.add_category('Pages with maps missing in infobox')
		mw.logObject('Missing map: ' .. map.map)
		return mw.ext.TeamLiquidIntegration.resolve_redirect(map.map or ''), map.map
	end
	return info.link, info.name
end

---@param map table
---@param opponent table
---@param opponentIndex integer
---@return {civ: string?, flag: string?, displayName: string?, pageName: string?}[]
function CustomMatchGroupInput.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local players
	if opponent.type == Opponent.team then
		players = Array.parseCommaSeparatedString(map['players' .. opponentIndex])
	else
		players = Array.map(opponent.match2players, Operator.property('name'))
	end
	local civs = Array.parseCommaSeparatedString(map['civs' .. opponentIndex])

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local player = players[playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local civ = Logic.emptyOr(civs[playerIndex], Faction.defaultFaction)
			civ = Faction.read(civ, {game = Game.abbreviation{game = map.game}:lower()})
			return {
				civ = civ,
				displayName = playerIdData.displayname or playerInputData.name,
				pageName = playerIdData.name or playerInputData.name,
				flag = playerIdData.flag,
				index = playerIndex,
			}
		end
	)

end

---@param winnerInput string|integer|nil
---@param finished boolean
---@return fun(opponentIndex: integer): integer?
function CustomMatchGroupInput.calculateMapScore(winnerInput, finished)
	local winner = tonumber(winnerInput)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner and not finished then
			return
		end
		return winner == opponentIndex and 1 or 0
	end
end

---@param match table
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	return {
		comment = map.comment,
	}
end

return CustomMatchGroupInput
