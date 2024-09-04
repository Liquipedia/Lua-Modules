---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Utils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Info = require('Module:Info')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Lpdb = Lua.import('Module:Lpdb')
local Faction = Lua.import('Module:Faction')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Widget = Lua.import('Module:Infobox/Widget/All')

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

SquadUtils.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
	military = 'Team/military',
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
	newPlayer.inactivedate = newPlayer.leavedate

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

	local id = assert(String.nilIfEmpty(args.id), 'Something is off with your input!')
	local person = Lpdb.SquadPlayer:new{
		id = id,
		link = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or id),
		name = String.nilIfEmpty(args.name),
		nationality = Flags.CountryName(args.flag),

		position = String.nilIfEmpty(args.position),
		role = (String.nilIfEmpty(args.role) and mw.getContentLanguage():ucfirst(args.role))
			or ((String.isNotEmpty(args.captain) or String.isNotEmpty(args.igl)) and 'Captain')
			or nil,
		teamtemplate = getTeamInfo(mw.title.getCurrentTitle().baseText, 'templatename'),

		newteam = getTeamInfo(args.newteam, 'page'),
		newteamrole = String.nilIfEmpty(args.newteamrole) or String.nilIfEmpty(args.newrole),
		newteamtemplate = getTeamInfo(args.newteam, 'templatename'),

		joindate = ReferenceCleaner.clean(args.joindate),
		leavedate = ReferenceCleaner.clean(args.leavedate),
		inactivedate = ReferenceCleaner.clean(args.inactivedate),

		status = SquadUtils.SquadTypeToStorageValue[args.type],

		extradata = {
			loanedto = args.team,
			loanedtorole = args.teamrole,
			newteamdate = String.nilIfEmpty(ReferenceCleaner.clean(args.newteamdate)),
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
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		squadPerson:save()
	end
end

---@param frame table
---@param squadClass Squad
---@param personFunction fun(player: table, squadType: integer):WidgetTableRowNew
---@param injector WidgetInjector?
---@return Html
function SquadUtils.defaultRunManual(frame, squadClass, personFunction, injector)
	local args = Arguments.getArgs(frame)
	local injectorInstance = (injector and injector()) or
		(Info.config.squads.hasPosition and SquadUtils.positionHeaderInjector()()) or
		nil
	local squad = squadClass(args, injectorInstance):title()
	local players = SquadUtils.parsePlayers(squad.args)

	if squad.type == SquadUtils.SquadType.FORMER and SquadUtils.anyInactive(players) then
		squad.type = SquadUtils.SquadType.FORMER_INACTIVE
	end

	squad:header()

	Array.forEach(players, function(player)
		squad:row(personFunction(player, squad.type))
	end)

	return squad:create()
end

---@param players table[]
---@param squadType integer
---@param squadClass Squad
---@param rowCreator fun(person: table, squadType: integer):WidgetTableRowNew
---@param customTitle string?
---@param injector? WidgetInjector
---@param personMapper? fun(person: table): table
---@return Html?
function SquadUtils.defaultRunAuto(players, squadType, squadClass, rowCreator, customTitle, injector, personMapper)
	local args = {type = squadType, title = customTitle}
	local injectorInstance = (injector and injector()) or
		(Info.config.squads.hasPosition and SquadUtils.positionHeaderInjector()()) or
		nil
	local squad = squadClass(args, injectorInstance):title():header()

	local mappedPlayers = Array.map(players, personMapper or SquadUtils.convertAutoParameters)
	Array.forEach(mappedPlayers, function(player)
		squad:row(rowCreator(player, squad.type))
	end)

	return squad:create()
end

---@param squadRowClass SquadRow
---@return fun(person: table, squadType: integer):WidgetTableRowNew
function SquadUtils.defaultRow(squadRowClass)
	return function(person, squadType)
		local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
		SquadUtils.storeSquadPerson(squadPerson)
		local row = squadRowClass(squadPerson)

		row:id():name()
		if Info.config.squads.hasPosition then
			row:position()
		else
			row:role()
		end
		row:date('joindate', 'Join Date:&nbsp;')

		if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date('inactivedate', 'Inactive Date:&nbsp;')
		end

		if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date('leavedate', 'Leave Date:&nbsp;')
			row:newteam()
		end

		return row:create()
	end
end

---@return WidgetInjector
function SquadUtils.positionHeaderInjector()
	local CustomInjector = Class.new(Injector)

	function CustomInjector:parse(id, widgets)
		if id == 'header_role' then
			return {
				Widget.TableCellNew{content = {'Position'}, header = true}
			}
		end

		return widgets
	end

	return CustomInjector
end

return SquadUtils
