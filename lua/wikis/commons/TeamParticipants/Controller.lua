---
-- @Liquipedia
-- page=Module:TeamParticipants/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Condition = Lua.import('Module:Condition')
local BooleanOperator = Condition.BooleanOperator
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local TeamParticipantsWikiParser = Lua.import('Module:TeamParticipants/Parse/Wiki')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')
local TeamService = Lua.import('Module:Service/Team')

local TeamParticipantsDisplay = Lua.import('Module:Widget/Participants/Team/CardsGroup')

local TeamParticipantsController = {}

local AUTO_IMPORTED_STAFF_ROLES = {
	'coach',
	'head coach',
}

---@param frame Frame
---@return Widget
function TeamParticipantsController.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local parsedArgs = Json.parseStringifiedArgs(args)
	local parsedData = TeamParticipantsWikiParser.parseWikiInput(parsedArgs)
	TeamParticipantsController.importParticipants(parsedData)
	TeamParticipantsController.fillIncompleteRosters(parsedData)

	local shouldStore =
		Logic.readBoolOrNil(args.store) ~= false and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))

	if shouldStore then
		Array.forEach(parsedData.participants, TeamParticipantsRepository.save)
	end
	Array.forEach(parsedData.participants, TeamParticipantsRepository.setPageVars)
	return TeamParticipantsDisplay{
		participants = parsedData.participants
	}
end

--- Imports participants' squad members from the database if requested.
--- Determines played status
--- May mutate the input.
---@param parsedData {participants: TeamParticipant[], expectedPlayerCount: integer?}
function TeamParticipantsController.importParticipants(parsedData)
	local playedData = TeamParticipantsController.playedDataFromMatchData(parsedData.participants)

	Array.forEach(parsedData.participants, function (participant)
		local players = participant.opponent.players
		-- Bad structure, this should always exist
		if not players then
			return
		end

		TeamParticipantsController.applyPlayed(
			players,
			participant.autoPlayed and playedData[participant.opponent.name] or nil
		)

		if not Logic.readBool(participant.shouldImportFromDb) then
			return
		end

		local importedPlayers = TeamParticipantsController.importSquadMembersFromDatabase(participant)
		if not importedPlayers then
			return
		end

		TeamParticipantsController.mergManualAndImportedPlayers(players, importedPlayers)
	end)
end

---@param participants TeamParticipant[]
---@return table<string, {pageName: string, displayName: string, flag: string?, faction: string?}[]>
function TeamParticipantsController.playedDataFromMatchData(participants)
	if not Array.any(participants, Operator.property('autoPlayed')) then
		return {}
	end
	local parent = Variables.varDefault('tournament_parent', mw.title.getCurrentTitle().prefixedText:gsub(' ', '_'))
	local playedData = {}
	Lpdb.executeMassQuery(
		'match2',
		{
			conditions = tostring(ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('finished'), Comparator.eq, 1),
				ConditionNode(ColumnName('parent'), Comparator.eq, parent),
			}),
			query = 'match2opponents, match2games'
		},
		FnUtil.curry(FnUtil.curry(TeamParticipantsController.getPlayedPlayersFromMatch, participants), playedData)
	)

	return Table.map(playedData, function(opponentName, playedPlayers)
		return opponentName, Array.extractValues(playedPlayers)
	end)
end

---@param playedData table<string, table<string, {pageName: string, displayName: string, flag: string?, faction: string?}>>
---@param participants TeamParticipant[]
---@param match match2
function TeamParticipantsController.getPlayedPlayersFromMatch(playedData, participants, match)
	-- we only care for team matches
	if Array.any(match.match2opponents, function(opponent) return opponent.type ~= Opponent.team end) then
		return
	end

	---@param template string
	---@return string?
	local determineTeamName = function(template)
		local participant = Array.find(participants, function(participant)
			return Array.any(participant.aliases, function(alias)
				return alias == template
			end)
		end)
		if not participant then return end
		return participant.opponent.name
	end

	---@type table<integer, string>
	local opponentNames = {}
	-- can not us Array.map since we might have opponents in match data that do not have a participant entry
	Array.forEach(match.match2opponents, function(opponent, opponentIndex)
		opponentNames[opponentIndex] = determineTeamName(opponent.template)
	end)

	Array.forEach(match.match2games, function(game)
		local gameOpponents = game.opponents
		if type(gameOpponents) ~= 'table' then
			gameOpponents = Json.parseIfTable(gameOpponents) or {}
		end
		Array.forEach(gameOpponents, function(opp, opponentIndex)
			local matchOpponent = match.match2opponents[opponentIndex]
			if not matchOpponent then return end
			local opponentName = opponentNames[opponentIndex]

			-- opp.players may have gaps, hence can not use Array.forEach
			Table.iter.forEachPair(opp.players or {}, function(playerIndex, player)
				local matchPlayer = matchOpponent.players[playerIndex]
				if Logic.isEmpty(player) or Logic.isEmpty(matchPlayer) then
					return
				end
				local matchPlayerName = matchPlayer.name
				if playedData[opponentName][matchPlayerName] then
					return
				end
				playedData[opponentName][matchPlayerName] = {
					pageName = matchPlayerName,
					displayName = matchPlayer.displayname,
					flag = matchPlayer.flag,
					faction = (matchPlayer.extradata or {}).faction,
				}
			end)
		end)
	end)
end

---@param players standardPlayer[]
---@param playedData {pageName: string, displayName: string, flag: string?}[]?
function TeamParticipantsController.applyPlayed(players, playedData)
	local autoHasPlayed = function(pageName)
		if Logic.isEmpty(playedData) then
			return nil
		end
		---@cast playedData -nil
		return Array.any(playedData, function(referencePlayer)
			return referencePlayer.pageName == pageName
		end)
	end

	Array.forEach(players, function(player)
		player.extradata.played = Logic.nilOr(
			player.extradata.played,
			autoHasPlayed(player.pageName),
			player.extradata.type ~= 'sub' and player.extradata.type ~= 'staff'
		)
	end)
end

---@param participant TeamParticipant
---@return standardPlayer[]?
function TeamParticipantsController.importSquadMembersFromDatabase(participant)
	local team = TeamService.getTeamByTemplate(participant.opponent.template)
	if not team then
		return
	end

	local squad = TeamService.getSquadBetween(team, DateExt.getStartDateOrNow(), participant.date)
	local membersToImport = Array.filter(squad, function (member)
		if member.type == 'player' then
			return true
		end
		return Array.find(AUTO_IMPORTED_STAFF_ROLES, function (role)
			return role == member.role:lower()
		end) ~= nil
	end)

	return Array.map(membersToImport, function (member)
		local memberType = member.type
		if member.hasLeft then
			memberType = 'former'
		elseif member.role and member.role:lower() == 'substitute' then
			memberType = 'sub'
		end
		return TeamParticipantsWikiParser.parsePlayer{
			member.displayName,
			link = member.pageName,
			flag = member.nationality,
			faction = member.faction,
			role = member.role,
			type = memberType,
		}
	end)
end

--- Merges players from the second parameters into the first parameter.
--- If a player exists in both lists, the two entries are deep merged, with the first parameter taking precedence.
---@param manualPlayers standardPlayer[]
---@param importedPlayers standardPlayer[]
function TeamParticipantsController.mergeManualAndImportedPlayers(manualPlayers, importedPlayers)
	Array.forEach(importedPlayers, function (player)
		local indexOfManualPlayer = Array.indexOf(manualPlayers, function (p)
			return p.pageName == player.pageName
		end)

		if indexOfManualPlayer == 0 then
			table.insert(manualPlayers, player)
		else
			local newPlayer = Table.deepMerge(player, manualPlayers[indexOfManualPlayer])
			manualPlayers[indexOfManualPlayer] = newPlayer
		end
	end)
end

--- Fills incomplete rosters for all participants with TBD players if needed.
--- May mutate the input.
---@param parsedData {participants: TeamParticipant[], expectedPlayerCount: integer?}
function TeamParticipantsController.fillIncompleteRosters(parsedData)
	Array.forEach(parsedData.participants, function (participant)
		if participant.opponent.template == 'tbd' then
			return
		end

		TeamParticipantsWikiParser.fillIncompleteRoster(participant.opponent, parsedData.expectedPlayerCount)
	end)
end

return TeamParticipantsController
