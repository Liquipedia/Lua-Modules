---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Info = require('Module:Info')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	if not Info.config.squad.allowManual then
		error('This wiki do not use manual squad tables')
	end
	local squad = Squad():init(frame):title()

	local players = SquadUtils.parsePlayers(squad.args)

	if squad.type == SquadUtils.SquadType.FORMER and SquadUtils.anyInactive(players) then
		squad.type = SquadUtils.SquadType.FORMER_INACTIVE
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
	if #playerList == 0 then
		return
	end

	local squad = Squad():init{type = squadType}:title():header()

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(SquadUtils.convertAutoParameters(player), squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRowNew
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

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end
	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole or player.newrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	end

	return row:create(SquadUtils.defaultObjectName(player, squadType))
end

return CustomSquad
