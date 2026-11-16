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
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')

local TeamParticipantsWikiParser = Lua.import('Module:TeamParticipants/Parse/Wiki')
local TeamParticipantsRepository = Lua.import('Module:TeamParticipants/Repository')
local TeamParticipantsRoster = Lua.import('Module:TeamParticipants/Roster')
local TeamService = Lua.import('Module:Service/Team')

local TeamParticipantsDisplay = Lua.import('Module:Widget/Participants/Team/CardsGroup')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')

local TeamParticipantsController = {}

local AUTO_IMPORTED_STAFF_ROLES = {
	'coach',
	'head coach',
}

local Config = Info.config.participants or {}

---@param frame Frame
---@return VNode
function TeamParticipantsController.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local parsedArgs = Json.parseStringifiedArgs(args)
	local parsedData = TeamParticipantsWikiParser.parseWikiInput(parsedArgs)

	local brokenParticipants = Array.filter(parsedData.participants, function(p) return p.broken end)
	parsedData.participants = Array.filter(parsedData.participants, function(p) return not p.broken end)

	if #brokenParticipants > 0 then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing team templates')
	end

	TeamParticipantsController.processParticipants(parsedData)

	local shouldStore = Logic.readBoolOrNil(args.store) ~= false and Lpdb.isStorageEnabled()

	if shouldStore then
		Array.forEach(parsedData.participants, TeamParticipantsRepository.save)
	end
	Array.forEach(parsedData.participants, TeamParticipantsRepository.setPageVars)

	local showControls = not teamParticipantsVars:get('externalControlsRendered')

	return TeamParticipantsDisplay{
		participants = parsedData.participants,
		brokenParticipants = brokenParticipants,
		showPlayerInfo = Logic.readBool(args.showplayerinfo),
		showControls = showControls,
		mergeStaffTabIfOnlyOneStaff = Logic.nilOr(
			Logic.readBoolOrNil(args.mergeStaffTabIfOnlyOneStaff), Logic.readBool(Config.mergeStaffTabIfOnlyOneStaff)
		),
		sortAlphabetically = parsedData.sortAlphabetically,
	}
end

--- Order matters: flags resolve last so earlier steps can tell manual input from defaults.
---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.processParticipants(parsedData)
	Array.forEach({
		TeamParticipantsController.importParticipants,
		TeamParticipantsController.fillIncompleteRosters,
		TeamParticipantsController.applyAutoPlayed,
		TeamParticipantsController.enrichPlayerDates,
		TeamParticipantsController.resolvePlayerFlags,
	}, function(step)
		step(parsedData)
	end)
end

---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.importParticipants(parsedData)
	local toImport = Array.filter(parsedData.participants, function(participant)
		return participant.shouldImportFromDb and participant.opponent.players ~= nil
	end)
	Array.forEach(toImport, function(participant)
		local importedPlayers = TeamParticipantsController.importSquadMembersFromDatabase(participant)
		if importedPlayers then
			TeamParticipantsRoster.mergeImportedPlayers(participant.opponent.players, importedPlayers)
		end
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
		return member.type == 'player' or Table.includes(AUTO_IMPORTED_STAFF_ROLES, member.role:lower())
	end)

	return Array.map(membersToImport, function (member)
		local status
		if member.hasLeft then
			status = 'former'
		elseif member.role and member.role:lower() == 'substitute' then
			status = 'sub'
		end
		return TeamParticipantsWikiParser.parsePlayer{
			member.displayName,
			link = member.pageName,
			flag = member.nationality,
			faction = member.faction,
			role = member.role,
			type = member.type,
			status = status,
		}
	end)
end

---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.fillIncompleteRosters(parsedData)
	Array.forEach(parsedData.participants, function(participant)
		if participant.opponent.template ~= 'tbd' then
			TeamParticipantsRoster.fillIncompleteRoster(participant.opponent, parsedData.expectedPlayerCount)
		end
	end)
end

---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.applyAutoPlayed(parsedData)
	Array.forEach(Array.filter(parsedData.participants, Operator.property('autoPlayed')), function(participant)
		local playedPlayers = TeamParticipantsRepository.getPlayedPlayers(participant.aliases)
		if not playedPlayers then
			return
		end
		local unlisted = TeamParticipantsRoster.applyPlayed(participant.opponent.players or {}, playedPlayers)
		if #unlisted == 0 then
			return
		end
		participant.warnings = participant.warnings or {}
		table.insert(participant.warnings, 'Played in matches but missing from the roster: '
			.. (table.concat(unlisted, ', '):gsub('_', ' ')))
	end)
end

--- Explicit dates from wiki input take precedence over the transfer-based ones.
---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.enrichPlayerDates(parsedData)
	if not parsedData.enrichPlayerDates then
		return
	end
	Array.forEach(parsedData.participants, function(participant)
		local players = participant.opponent.players or {}
		local datesByPlayer = TeamParticipantsRepository.getPlayersDates(players, participant.aliases)
		Array.forEach(players, function(player)
			local dates = datesByPlayer[player.pageName] or {}
			player.extradata = player.extradata or {}
			player.extradata.joinDate = dates.joinDate
			player.extradata.leaveDate = dates.leaveDate
		end)
	end)
end

---@param parsedData TeamParticipantsParsedData
function TeamParticipantsController.resolvePlayerFlags(parsedData)
	Array.forEach(Array.flatMap(parsedData.participants, function(participant)
		return participant.opponent.players or {}
	end), TeamParticipantsRoster.resolvePlayerFlags)
end

return TeamParticipantsController
