
local Lua = require('Module:Lua')
local ReferenceCleaner = Lua.import('Module:ReferenceCleaner')
local TransferRefs = Lua.import('Module:Transfer/References')
local Faction = Lua.import('Module:Faction')
local Table = Lua.import('Module:Table')
local Lpdb = Lua.import('Module:Lpdb')
local Json = Lua.import('Module:Json')
local Flags = Lua.import('Module:Flags')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Info = Lua.import('Module:Info', {loadData = true})
local Array = Lua.import('Module:Array')
local Variables = Lua.import('Module:Variables')

local SquadParsingUtil = {}

---@param args table
---@return table[]
function SquadParsingUtil.parsePlayers(args)
	return Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)
end

function SquadParsingUtil.createWrapperData(players, squadType, squadStatus, title)
	return {
		players = players,
		squadType = squadType,
		squadStatus = squadStatus,
		title = title,
	}
end

function SquadParsingUtil.readWrapperArgs(args)
	local players = SquadParsingUtil.parsePlayers(args)

	local squadType = SquadParsingUtil.TypeToSquadType[args.type] or SquadParsingUtil.SquadType.PLAYER
	local squadStatus = SquadParsingUtil.statusToSquadStatus(args.status) or SquadParsingUtil.SquadStatus.ACTIVE

	if squadStatus == SquadParsingUtil.SquadStatus.FORMER and SquadParsingUtil.anyInactive(players) then
		squadStatus = SquadParsingUtil.SquadStatus.FORMER_INACTIVE
	end

	return SquadParsingUtil.createWrapperData(players, squadType, squadStatus, args.title)
end

---@param player table
---@return table
function SquadParsingUtil.convertAutoParameters(player)
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
function SquadParsingUtil.readSquadPersonArgs(args)
	local function getTeamInfo(page, property)
		if not page or not TeamTemplate.exists(page) then
			return
		end
		return TeamTemplate.getRawOrNil(page)[property]
	end

	local name = String.nilIfEmpty(args.name)
	local id = String.nilIfEmpty(args.id) or name
	assert(id, 'id or name parameter is required')

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

		status = SquadParsingUtil.SquadStatusToStorageValue[args.status],
		type = SquadParsingUtil.SquadTypeToStorageValue[args.type],

		extradata = {
			loanedto = args.team,
			loanedtorole = args.teamrole,
			activeteam = args.activeteam,
			activeteamrole = args.activeteamrole,
			newteamdate = String.nilIfEmpty(ReferenceCleaner.clean{input = args.newteamdate}),
			faction = Faction.read(args.faction or args.race),
		},
	}

	if Info.config.squads.hasSpecialTeam and not person.newteam and args.newteam then
		person.newteamspecial = SquadParsingUtil.specialTeamsTemplateMapping[args.newteam]
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
