---
-- @Liquipedia
-- wiki=smite
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

local CustomSquad = {}
local CustomInjector = Class.new(Injector)

function CustomInjector:parse(id, widgets)
	if id == 'header_role' then
		return {
			Widget.TableCellNew{content = {'Position'}, header = true}
		}
	end

	return widgets
end

---@param frame Frame
function CustomSquad.run(frame)
	error('SMITE wiki doesn\'t support manual Squad Tables')
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = Squad():init({type = squadType}, CustomInjector()):title():header()

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRowNew
function CustomSquad._playerRow(player, squadType)
	local row = SquadRow()

	--Get Reference(s)
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	local joinText = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	local leaveText = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference

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
	row:position{role = player.thisTeam.role, position = player.thisTeam.position}
	row:date(joinText, 'Join Date:&nbsp;', 'joindate')

	if squadType == SquadUtils.SquadType.FORMER then
		row:date(leaveText, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam({
			newteam = player.newTeam.team,
			newteamrole = player.newTeam.role,
			newteamdate = player.newTeam.date,
			leavedate = player.newTeam.date
		})
	elseif squadType == SquadUtils.SquadType.INACTIVE then
		row:date(leaveText, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create()
end

return CustomSquad
