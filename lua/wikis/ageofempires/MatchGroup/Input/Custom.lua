---
-- @Liquipedia
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

local CustomMatchGroupInput = {}
local OPPONENT_CONFIG = {
	resolveRedirect = true,
	pagifyTeamNames = true,
}

local MatchFunctions = {
	OPPONENT_CONFIG = OPPONENT_CONFIG,
}
local MapFunctions = {
	BREAK_ON_EMPTY = true,
	INHERIT_MAP_DATES = true,
}

local FffMatchFunctions = {
	OPPONENT_CONFIG = OPPONENT_CONFIG,
}
---@type FfaMapParserInterface
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))
	match.game, match.mapsInfo = MatchFunctions.getGameAndMapsFromTournament(match)

	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FffMatchFunctions)
end

--- Normal 2-opponent Match

---@param match table
---@param opponentIndex integer
---@param options readOpponentOptions
---@return table?
function MatchFunctions.readOpponent(match, opponentIndex, options)
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
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param bestofInput string|integer?
---@param maps table[]
---@return integer?
function MatchFunctions.getBestOf(bestofInput, maps)
	local bestof = tonumber(bestofInput) or tonumber(Variables.varDefault('bestof'))

	if bestof then
		Variables.varDefine('bestof', bestof)
	end

	return bestof
end

---@param opponents table[]
---@return string
function MatchFunctions.getMode(opponents)
	return Opponent.toLegacyMode(opponents[1].type, opponents[2].type)
end

---@param match table
---@return string?, table?
function MatchFunctions.getGameAndMapsFromTournament(match)
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
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

---@param match table
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
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
---@param mapIndex integer
---@param match table
---@return string?
---@return string?
function MapFunctions.getMapName(map, mapIndex, match)
	---@type {name: string, link: string}[]?
	local mapsInfo = match.mapsInfo
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
function MapFunctions.getPlayersOfMapOpponent(map, opponent, opponentIndex)
	local players
	if opponent.type == Opponent.team then
		players = Array.parseCommaSeparatedString(map['players' .. opponentIndex])
	elseif opponent.type == Opponent.solo then
		players = Array.map(opponent.match2players, Operator.property('name'))
	else
		-- Party of 2 or more players
		players = Logic.emptyOr(
			Array.parseCommaSeparatedString(map['players' .. opponentIndex]),
			Array.map(opponent.match2players, Operator.property('name'))
		) or {}
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

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local winner = tonumber(map.winner)
	return function(opponentIndex)
		-- TODO Better to check if map has started, rather than finished, for a more correct handling
		if not winner then
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
		mapmode = Table.extract(map, 'mode'),
	}
end

---@param match table
---@param map table
---@return string?
function MapFunctions.getGame(match, map)
	return Logic.emptyOr(map.game, match.game, Variables.varDefault('tournament_game'))
end

--- FFA Match

---@param match table
---@param opponents table[]
---@param scoreSettings table
---@return table[]
function FffMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents table[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FffMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

---@param match table
---@param games table[]
---@param opponents table[]
---@param settings table
---@return table
function FffMatchFunctions.getExtraData(match, games, opponents, settings)
	return {
		placementinfo = settings.placementInfo,
		settings = settings.settings,
	}
end

FfaMapFunctions.getMapName = MapFunctions.getMapName
FfaMapFunctions.getGame = MapFunctions.getGame

---@param map table
---@param opponent table
---@param opponentMapInput table
---@return {civ: string?, flag: string?, displayName: string?, pageName: string?}[]
function FfaMapFunctions.getPlayersOfMapOpponent(map, opponent, opponentMapInput)
	local players = Array.map(opponent.match2players, Operator.property('name'))
	local factions = Array.parseCommaSeparatedString(opponentMapInput['civs'])

	return MatchGroupInputUtil.parseMapPlayers(
		opponent.match2players,
		players,
		function(playerIndex)
			local player = players[playerIndex]
			return player and {name = player} or nil
		end,
		function(playerIndex, playerIdData, playerInputData)
			local faction = Logic.emptyOr(factions[playerIndex], Faction.defaultFaction)
			faction = Faction.read(faction, {game = Game.abbreviation{game = map.game}:lower()})
			return {
				faction = faction,
			}
		end
	)
end

return CustomMatchGroupInput
