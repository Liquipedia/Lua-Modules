---
-- @Liquipedia
-- page=Module:Features/Squad/Lib/Parse
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Flags = Lua.import('Module:Flags')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Lpdb = Lua.import('Module:Lpdb')
local Faction = Lua.import('Module:Faction')
local TransferRefs = Lua.import('Module:Transfer/References')
local SquadTypes = Lua.import('Module:Features/Squad/Types')

local SquadParse = {}

---@param status string?
---@return SquadStatus?
function SquadParse.statusToSquadStatus(status)
	if not status then
		return
	end

	return SquadTypes.StatusToSquadStatus[status:lower()]
end

---@param args table
---@return table[]
function SquadParse.parsePlayers(args)
	return Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)
end

---@param players {inactivedate: string|nil}[]
---@return boolean
function SquadParse.anyInactive(players)
	return Array.any(players, function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end)
end

---@param players table[]
---@param squadType SquadType
---@param squadStatus SquadStatus
---@param title string?
---@param args table?
---@return SquadWrapper
function SquadParse.createWrapperData(players, squadType, squadStatus, title, args)
	return {
		players = players,
		squadType = squadType,
		squadStatus = squadStatus,
		title = title,
		args = args or {},
	}
end

---@param args table
---@return SquadWrapper
function SquadParse.readWrapperArgs(args)
	local players = SquadParse.parsePlayers(args)

	local squadType = SquadTypes.TypeToSquadType[args.type] or SquadTypes.SquadType.PLAYER
	local squadStatus = SquadParse.statusToSquadStatus(args.status) or SquadTypes.SquadStatus.ACTIVE

	if squadStatus == SquadTypes.SquadStatus.FORMER and SquadParse.anyInactive(players) then
		squadStatus = SquadTypes.SquadStatus.FORMER_INACTIVE
	end

	return SquadParse.createWrapperData(players, squadType, squadStatus, args.title, args)
end

---@param player table
---@return SquadPersonArgs
function SquadParse.convertAutoParameters(player)
	---@type SquadPersonArgs
	local newPlayer = Table.copy(player)
	local joinReference = TransferRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = TransferRefs.useReferences(player.leavedateRef, player.leavedate)

	-- Map between formats
	newPlayer.joindate = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	newPlayer.leavedate = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference
	newPlayer.inactivedate = newPlayer.leavedate

	newPlayer.link = String.nilIfEmpty(player.page)
	newPlayer.role = player.thisTeam.role
	newPlayer.position = player.thisTeam.position
	newPlayer.team = player.thisTeam.role == 'Loan' and player.oldTeam.team or nil

	newPlayer.newteam = player.newTeam.team
	newPlayer.newteamrole = player.newTeam.role
	newPlayer.newteamdate = player.newTeam.date

	return newPlayer
end

---@param args SquadPersonArgs
---@return ModelRow
function SquadParse.readSquadPersonArgs(args)
	local function getTeamInfo(page, property)
		if not page or not TeamTemplate.exists(page) then
			return
		end
		return TeamTemplate.getRawOrNil(page)[property]
	end

	local name = String.nilIfEmpty(args.name)
	local id = String.nilIfEmpty(args.id) or name
	assert(id, 'id or name is required')

	local person = Lpdb.SquadPlayer:new{
		id = id,
		link = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or id),
		name = name,
		nationality = Flags.CountryName{flag = args.flag},

		position = String.nilIfEmpty(args.position),
		role = (String.nilIfEmpty(args.role) and mw.getContentLanguage():ucfirst(args.role))
			or ((String.isNotEmpty(args.captain) or String.isNotEmpty(args.igl)) and 'Captain')
			or nil,
		teamtemplate = getTeamInfo(mw.title.getCurrentTitle().baseText, 'templatename'),

		newteam = getTeamInfo(args.newteam, 'page'),
		newteamrole = String.nilIfEmpty(args.newteamrole) or String.nilIfEmpty(args.newrole),
		newteamtemplate = getTeamInfo(args.newteam, 'templatename'),

		joindate = ReferenceCleaner.clean{input = args.joindate},
		joindateref = args.joindateref,
		leavedate = ReferenceCleaner.clean{input = args.leavedate},
		leavedateref = args.leavedateref,
		inactivedate = ReferenceCleaner.clean{input = args.inactivedate},
		inactivedateref = args.inactivedateref,

		status = SquadTypes.SquadStatusToStorageValue[args.status],
		type = SquadTypes.SquadTypeToStorageValue[args.type],

		extradata = {
			loanedto = args.team,
			loanedtorole = args.teamrole,
			newteamdate = String.nilIfEmpty(ReferenceCleaner.clean{input = args.newteamdate}),
			faction = Faction.read(args.faction or args.race),
			activeteam = args.activeteam,
			activeteamrole = args.activeteamrole,
			game = args.game,
		},
	}

	if Info.config.squads.hasSpecialTeam and not person.newteam and args.newteam then
		person.extradata.newteamspecial = SquadTypes.specialTeamsTemplateMapping[args.newteam]
	end

	if person.joindate ~= args.joindate then
		person.extradata.joindatedisplay = args.joindate
	end

	if person.leavedate ~= args.leavedate then
		person.extradata.leavedatedisplay = args.leavedate
	end

	if person.inactivedate ~= args.inactivedate then
		person.extradata.inactivedatedisplay = args.inactivedate
	end

	return person
end

return SquadParse
