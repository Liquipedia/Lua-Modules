---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title():header()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)

	Array.forEach(players, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if #playerList == 0 then
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
		player.position = player.thisTeam.position
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
	local row = SquadRow()

	row:status(squadType)
	row:id{
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
		date = player.leavedate or player.inactivedate or player.leavedate,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.SquadType.FORMER then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	elseif squadType == Squad.SquadType.INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
		.. (player.role and '_' .. player.role or '')
	)
end

return CustomSquad
