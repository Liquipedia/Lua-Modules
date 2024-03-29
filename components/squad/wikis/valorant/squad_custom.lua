---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)

	local hasInactive = function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end

	if squad.type == Squad.SquadType.FORMER and Array.any(players, hasInactive) then
		squad.type = Squad.SquadType.FORMER_INACTIVE
	end

	squad:header()

	Array.forEach(players, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = Squad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad:title():header()

	Array.forEach(playerList, function(player)
		--Get Reference(s)
		local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
		local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

		-- Map between formats
		player.joindate = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
		player.leavedate = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference
		player.inactivedate = player.leavedate

		player.link = player.page
		player.role = player.thisTeam.role
		player.team = player.thisTeam.role == 'Loan' and player.oldTeam.team

		player.newteam = player.newTeam.team
		player.newteamrole = player.newTeam.role
		player.newteamdate = player.newTeam.date

		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRow
function CustomSquad._playerRow(player, squadType)
	local row = SquadRow{useTemplatesForSpecialTeams = true}

	row:status(squadType)
	row:id{
		player.id,
		flag = player.flag,
		link = player.link,
		captain = player.captain or player.igl,
		role = player.role,
		team = player.team,
		teamrole = player.teamrole,
		date = player.leavedate or player.inactivedate or player.leavedate,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.SquadType.INACTIVE or squadType == Squad.SquadType.FORMER_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	if squadType == Squad.SquadType.FORMER or squadType == Squad.SquadType.FORMER_INACTIVE then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole or player.newrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText
		.. '_' .. player.id .. '_'
		.. ReferenceCleaner.clean(player.joindate)
		.. (player.role and '_' .. player.role or '')
		.. '_' .. squadType
	)
end

return CustomSquad
