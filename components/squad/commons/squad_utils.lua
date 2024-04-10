---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local Json = require('Module:Json')
local Lpdb = require('Module:Lpdb')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local SquadUtils = {}

---@enum SquadType
SquadUtils.SquadType = {
	ACTIVE = 0,
	INACTIVE = 1,
	FORMER = 2,
	FORMER_INACTIVE = 3,
}

---@type {string: SquadType}
SquadUtils.StatusToSquadType = {
	active = SquadUtils.SquadType.ACTIVE,
	inactive = SquadUtils.SquadType.INACTIVE,
	former = SquadUtils.SquadType.FORMER,
}

---@type {SquadType: string}
SquadUtils.SquadTypeToStorageValue = {
	[SquadUtils.SquadType.ACTIVE] = 'active',
	[SquadUtils.SquadType.INACTIVE] = 'inactive',
	[SquadUtils.SquadType.FORMER] = 'former',
	[SquadUtils.SquadType.FORMER_INACTIVE] = 'former',
}

-- TODO: Decided on all valid types
SquadUtils.validPersonTypes = {'player', 'staff'}
SquadUtils.defaultPersonType = 'player'

---@param status string?
---@return SquadType?
function SquadUtils.statusToSquadType(status)
	if not status then
		return
	end
	return SquadUtils.StatusToSquadType[status:lower()]
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
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	-- Map between formats
	newPlayer.joindate = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	newPlayer.leavedate = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference
	newPlayer.inactivedate = player.leavedate

	newPlayer.link = player.page
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
		if not page or not mw.ext.TeamTemplate.teamexists(page) then
			return
		end
		return mw.ext.TeamTemplate.raw(page)[property]
	end

	local id = assert(String.nilIfEmpty(args[1]), 'Something is off with your input!')
	return Lpdb.SquadPlayer:new{
		id = id,
		link = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or id),
		name = String.nilIfEmpty(args.name),
		nationality = Flags.CountryName(args.flag),

		position = String.nilIfEmpty(args.position),
		role = String.nilIfEmpty(args.role) or (String.isNotEmpty(args.captain) and 'Captain') or nil, -- TODO UC First?
		teamtemplate = getTeamInfo(mw.title.getCurrentTitle().baseText, 'templatename'),

		newteam = getTeamInfo(args.newteam, 'page'),
		newteamrole = String.nilIfEmpty(args.newteamrole) or String.nilIfEmpty(args.newrole),
		newteamtemplate = getTeamInfo(args.newteam, 'templatename'),

		joindate = ReferenceCleaner.clean(args.joindate),
		leavedate = ReferenceCleaner.clean(args.leavedate),
		inactivedate = ReferenceCleaner.clean(args.inactivedate),

		status = SquadUtils.SquadTypeToStorageValue[args.status],
		type = args.type,

		extradata = {
			loanedto = args.team,
			loanedtorole = args.teamrole,
			newteamdate = args.newteamdate,
			faction = Faction.read(args.faction or args.race),
		},
	}
end

---@param squadPerson ModelRow
function SquadUtils.storeSquadPerson(squadPerson)
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		squadPerson:save()
	end
end

return SquadUtils
