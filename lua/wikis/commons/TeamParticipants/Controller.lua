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
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

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
--- May mutate the input.
---@param parsedData {participants: TeamParticipant[], expectedPlayerCount: integer?}
function TeamParticipantsController.importParticipants(parsedData)
	Array.forEach(parsedData.participants, function (participant)
		local players = participant.opponent.players
		-- Bad structure, this should always exist
		if not players then
			return
		end

		if Logic.readBool(participant.shouldImportFromDb) then
			local importedPlayers = TeamParticipantsController.importSquadMembersFromDatabase(participant)
			if importedPlayers then
				TeamParticipantsController.mergeManualAndImportedPlayers(players, importedPlayers)
			end
		end

		TeamParticipantsWikiParser.fillIncompleteRoster(participant.opponent, parsedData.expectedPlayerCount)
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
		elseif member.role:lower() == 'substitute' then
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

return TeamParticipantsController
