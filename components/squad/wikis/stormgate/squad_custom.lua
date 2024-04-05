---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title():header()

	local players = SquadUtils.parsePlayers(squad.args)

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
		local newPlayer = SquadUtils.convertAutoParameters(player)
		newPlayer.faction = Logic.emptyOr(player.thisTeam.position, player.newTeam.position)
		squad:row(CustomSquad._playerRow(newPlayer, squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return Html
function CustomSquad._playerRow(player, squadType)
	local row = SquadRow{useTemplatesForSpecialTeams = true}

	local faction = Faction.read(player.faction)

	row:status(squadType)
	row:id{
		player.id,
		flag = player.flag,
		faction = faction,
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
		date = player.leavedate or player.inactivedate or player.joindate,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == SquadUtils.SquadType.FORMER then
		if Logic.isEmpty(player.newteam) then
			if Logic.readBool(player.retired) then
				player.newteam = 'retired'
			elseif Logic.readBool(player.military) then
				player.newteam = 'military'
			end
		end

		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate,
		}
	elseif squadType == SquadUtils.SquadType.INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	row:setExtradata{faction = faction}

	return row:create(SquadUtils.defaultObjectName(player, squadType))
end

return CustomSquad
