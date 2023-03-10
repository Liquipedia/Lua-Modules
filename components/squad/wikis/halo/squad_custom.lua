---
-- @Liquipedia
-- wiki=halo
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Squad = Lua.import('Module:Squad', {requireDevIfEnabled = true})
local SquadRow = Lua.import('Module:Squad/Row', {requireDevIfEnabled = true})
local SquadAutoRefs = Lua.import('Module:SquadAuto/References', {requireDevIfEnabled = true})

local CustomSquad = {}

function CustomSquad.run(frame)
	error('Halo wiki doesn\'t support manual Squad Tables')
end

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

function CustomSquad._playerRow(player, squadType)
	--Get Reference(s)
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	local joinText = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	local leaveText = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference

	local row = SquadRow()
	row:id({
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.page,
		captain = player.captain,
		role = player.thisTeam.role,
		team = player.thisTeam.role == 'Loan' and player.oldTeam.team,
	})
	row:name({name = player.name})
	row:role({role = player.thisTeam.role})
	row:date(joinText, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.TYPE_FORMER then
		row:date(leaveText, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam({
			newteam = player.newTeam.team,
			newteamrole = player.newTeam.role,
			newteamdate = player.newTeam.date,
			leavedate = player.newTeam.date
		})
	elseif squadType == Squad.TYPE_INACTIVE then
		row:date(leaveText, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(mw.title.getCurrentTitle().prefixedText .. '_' .. player.id .. '_' .. player.joindate)
end

return CustomSquad
