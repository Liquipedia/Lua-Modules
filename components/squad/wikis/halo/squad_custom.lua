---
-- @Liquipedia
-- wiki=halo
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}

---@param frame Frame
function CustomSquad.run(frame)
	error('Halo wiki doesn\'t support manual Squad Tables')
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

	for _, player in pairs(playerList) do
		squad:row(CustomSquad._playerRow(player, squad.type))
	end

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRow
function CustomSquad._playerRow(player, squadType)
	--Get Reference(s)
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	local joinText = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	local leaveText = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference

	local row = SquadRow()
	row:status(squadType)
	row:id({
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.page,
		captain = player.captain,
		role = player.thisTeam.role,
		team = player.thisTeam.role == 'Loan' and player.oldTeam.team,
		date = player.leavedate or player.inactivedate or player.leavedate,
	})
	row:name({name = player.name})
	row:role({role = player.thisTeam.role})
	row:date(joinText, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.SquadType.FORMER then
		row:date(leaveText, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam({
			newteam = player.newTeam.team,
			newteamrole = player.newTeam.role,
			newteamdate = player.newTeam.date,
			leavedate = player.newTeam.date
		})
	elseif squadType == Squad.SquadType.INACTIVE then
		row:date(leaveText, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	local pageName = mw.title.getCurrentTitle().prefixedText
	return row:create(pageName .. '_' .. player.id .. '_' .. player.joindate .. '_' .. squadType)
end

return CustomSquad
