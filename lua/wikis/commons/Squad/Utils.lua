---
-- @Liquipedia
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
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
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')
local TransferRefs = Lua.import('Module:Transfer/References')

local SquadUtils = {}

---@enum SquadStatus
SquadUtils.SquadStatus = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3,
}

---@type {string: SquadStatus}
SquadUtils.StatusToSquadStatus = {
	active = SquadUtils.SquadStatus.ACTIVE,
	inactive = SquadUtils.SquadStatus.INACTIVE,
	former = SquadUtils.SquadStatus.FORMER,
}

---@type {SquadStatus: string}
SquadUtils.SquadStatusToStorageValue = {
	[SquadUtils.SquadStatus.ACTIVE] = 'active',
	[SquadUtils.SquadStatus.INACTIVE] = 'inactive',
	[SquadUtils.SquadStatus.FORMER] = 'former',
	[SquadUtils.SquadStatus.FORMER_INACTIVE] = 'former',
}

---@enum SquadType
SquadUtils.SquadType = {
	PLAYER = 0,
	STAFF = 1,
}

---@type {string: SquadType}
SquadUtils.TypeToSquadType = {
	player = SquadUtils.SquadType.PLAYER,
	staff = SquadUtils.SquadType.STAFF,
}

---@type {SquadType: string}
SquadUtils.SquadTypeToStorageValue = {
	[SquadUtils.SquadType.PLAYER] = 'player',
	[SquadUtils.SquadType.STAFF] = 'staff',
}

SquadUtils.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
	military = 'Team/military',
}

---@param status string?
---@return SquadStatus?
function SquadUtils.statusToSquadStatus(status)
	if not status then
		return
	end
	return SquadUtils.StatusToSquadStatus[status:lower()]
end

---@param args table
---@return table[]
function SquadUtils.parsePlayers(args)
	return Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)
end

---@param players {inactivedate: string|nil}[]
---@return boolean
function SquadUtils.anyInactive(players)
	return Array.any(players, function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end)
end

---@param player table
---@return table
function SquadUtils.convertAutoParameters(player)
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
	newPlayer.team = player.thisTeam.role == 'Loan' and player.oldTeam.team

	newPlayer.newteam = player.newTeam.team
	newPlayer.newteamrole = player.newTeam.role
	newPlayer.newteamdate = player.newTeam.date

	return newPlayer
end

---@param args table
---@return ModelRow
function SquadUtils.readSquadPersonArgs(args)
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
		leavedate = ReferenceCleaner.clean{input = args.leavedate},
		inactivedate = ReferenceCleaner.clean{input = args.inactivedate},

		status = SquadUtils.SquadStatusToStorageValue[args.status],
		type = SquadUtils.SquadTypeToStorageValue[args.type],

		extradata = {
			loanedto = args.team,
			loanedtorole = args.teamrole,
			newteamdate = String.nilIfEmpty(ReferenceCleaner.clean{input = args.newteamdate}),
			faction = Faction.read(args.faction or args.race),
		},
	}

	if Info.config.squads.hasSpecialTeam and not person.newteam and args.newteam then
		person.newteamspecial = SquadUtils.specialTeamsTemplateMapping[args.newteam]
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

---@param squadPerson ModelRow
function SquadUtils.storeSquadPerson(squadPerson)
	squadPerson:save()
end

---@param players table[]
---@param squadStatus SquadStatus
---@return table<string, boolean>
function SquadUtils.analyzeColumnVisibility(players, squadStatus)
	local isInactive = squadStatus == SquadUtils.SquadStatus.INACTIVE
		or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE
	local isFormer = squadStatus == SquadUtils.SquadStatus.FORMER
		or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE

	return {
		teamIcon = Array.any(players, function(p)
			return p.team and TeamTemplate.exists(p.team)
		end),
		name = Array.any(players, function(p)
			return String.isNotEmpty(p.name)
		end),
		role = Array.any(players, function(p)
			return String.isNotEmpty(p.role) or String.isNotEmpty(p.position)
		end),
		joindate = Array.any(players, function(p)
			return String.isNotEmpty(p.joindate)
		end),
		inactivedate = isInactive and Array.any(players, function(p)
			return String.isNotEmpty(p.inactivedate)
		end),
		leavedate = isFormer and Array.any(players, function(p)
			return String.isNotEmpty(p.leavedate)
		end),
		newteam = isFormer and Array.any(players, function(p)
			return String.isNotEmpty(p.newteam)
				or String.isNotEmpty(p.newteamrole)
				or String.isNotEmpty(p.newteamspecial)
		end),
	}
end

---@param frame table
---@param squadWidget SquadWidget
---@param rowCreator fun(player: table, squadStatus: SquadStatus, squadType: SquadType, columnVisibility: table):Widget
---@return Widget
function SquadUtils.defaultRunManual(frame, squadWidget, rowCreator)
	local args = Arguments.getArgs(frame)
	local props = {
		status = SquadUtils.statusToSquadStatus(args.status) or SquadUtils.SquadStatus.ACTIVE,
		title = args.title,
		type = SquadUtils.TypeToSquadType[args.type] or SquadUtils.SquadType.PLAYER,
	}
	local players = SquadUtils.parsePlayers(args)

	if props.status == SquadUtils.SquadStatus.FORMER and SquadUtils.anyInactive(players) then
		props.status = SquadUtils.SquadStatus.FORMER_INACTIVE
	end

	local columnVisibility = SquadUtils.analyzeColumnVisibility(players, props.status)
	props.children = Array.map(players, function(player)
		return rowCreator(player, props.status, props.type, columnVisibility)
	end)

	local output = squadWidget(props)
	output = SquadContexts.ColumnVisibility{value = columnVisibility, children = {output}}
	if Info.config.squads.hasPosition then
		output = SquadContexts.RoleTitle{value = SquadUtils.positionTitle(), children = {output}}
	end
	return output
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param squadWidget SquadWidget
---@param rowCreator fun(person: table, squadStatus: SquadStatus, squadType: SquadType, columnVisibility: table):Widget
---@param customTitle string?
---@param personMapper? fun(person: table): table
---@return Widget
function SquadUtils.defaultRunAuto(players, squadStatus, squadType, squadWidget, rowCreator, customTitle, personMapper)
	local mappedPlayers = Array.map(players, personMapper or SquadUtils.convertAutoParameters)
	local columnVisibility = SquadUtils.analyzeColumnVisibility(mappedPlayers, squadStatus)
	local props = {
		status = squadStatus,
		title = customTitle,
		type = squadType,
	}
	props.children = Array.map(mappedPlayers, function(player)
		return rowCreator(player, props.status, props.type, columnVisibility)
	end)

	local output = squadWidget(props)
	output = SquadContexts.ColumnVisibility{value = columnVisibility, children = {output}}
	if Info.config.squads.hasPosition then
		output = SquadContexts.RoleTitle{value = SquadUtils.positionTitle(), children = {output}}
	end
	return output
end

---@param squadRowClass SquadRow
---@return fun(person: table, squadStatus: SquadStatus, squadType: SquadType, columnVisibility: table?):Widget
function SquadUtils.defaultRow(squadRowClass)
	return function(person, squadStatus, squadType, columnVisibility)
		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {status = squadStatus, type = squadType}))
		SquadUtils.storeSquadPerson(squadPerson)
		local row = squadRowClass(squadPerson, columnVisibility)

		row:id():name()
		if Info.config.squads.hasPosition then
			row:position()
		else
			row:role()
		end
		row:date('joindate')

		if squadStatus == SquadUtils.SquadStatus.INACTIVE or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('inactivedate')
		end

		if squadStatus == SquadUtils.SquadStatus.FORMER or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
			row:date('leavedate')
			row:newteam()
		end

		return row:create()
	end
end

---@return string
function SquadUtils.positionTitle()
	return 'Position'
end

return SquadUtils
