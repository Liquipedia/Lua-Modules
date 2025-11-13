---
-- @Liquipedia
-- page=Module:TeamParticipants/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
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

	Array.forEach(parsedData.participants, function (participant)
		if not Logic.readBool(participant.shouldImportFromDb) then
			return
		end

		local team = TeamService.getTeamByTemplate(participant.opponent.template)
		if not team or not team.members then
			return
		end

		local activeMembers = Array.filter(team.members, function (member)
			return member.status == 'active'
		end)
		local membersToImport = Array.filter(activeMembers, function (member)
			if member.type == 'player' then
				return true
			end
			return Array.find(AUTO_IMPORTED_STAFF_ROLES, function (role)
				return role == member.role:lower()
			end) ~= nil
		end)

		local playersFromDatabase = Array.map(membersToImport, function (member)
			return TeamParticipantsWikiParser.parsePlayer{
				member.displayName,
				link = member.pageName,
				flag = member.nationality,
				faction = member.faction,
				role = member.role,
				type = member.type,
			}
		end)

		local manualPlayers = participant.opponent.players or {}
		for _, player in ipairs(playersFromDatabase) do
			local indexOfManualPlayer = Array.indexOf(manualPlayers, function (p)
				return p.pageName == player.pageName
			end)

			if indexOfManualPlayer == 0 then
				table.insert(manualPlayers, player)
			else
				local newPlayer = Table.deepMerge(player, manualPlayers[indexOfManualPlayer])
				manualPlayers[indexOfManualPlayer] = newPlayer
			end
		end
	end)

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

return TeamParticipantsController
