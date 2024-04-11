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
local Info = require('Module:Info')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

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

---@param frame table
---@param squadClass Squad
---@param personFunction fun(player: table, squadType: integer):WidgetTableRowNew
---@param injector WidgetInjector?
---@return Html
function SquadUtils.defaultRunManual(frame, squadClass, personFunction, injector)
	local args = Arguments.getArgs(frame)
	local squad = squadClass():init(args, injector and injector() or nil):title()

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
---@param injector? WidgetInjector
---@param personMapper? fun(person: table): table
---@return Html?
function SquadUtils.defaultRunAuto(players, squadType, squadClass, rowCreator, injector, personMapper)
	local args = {type = squadType}
	local squad = squadClass():init(args, injector and injector() or nil):title():header()

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
		local row = squadRowClass()

		row:status(squadType)
		row:id{
			(person.idleavedate or person.id),
			flag = person.flag,
			link = person.link,
			captain = person.captain or person.igl,
			role = person.role,
			team = person.team,
			teamrole = person.teamrole,
			date = person.leavedate or person.inactivedate,
		}
		row:name{name = person.name}
		if Info.config.squad.hasPosition then
			row:position{role = person.role, position = person.position}
		else
			row:role{role = person.role}
		end
		row:date(person.joindate, 'Join Date:&nbsp;', 'joindate')

		if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(person.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end
		if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(person.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = person.newteam,
				newteamrole = person.newteamrole or person.newrole,
				newteamdate = person.newteamdate,
				leavedate = person.leavedate
			}
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
