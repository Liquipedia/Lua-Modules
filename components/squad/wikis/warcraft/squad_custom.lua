---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow)
end

function CustomSquad._playerRow(player, squadType)
	local row = SquadRow{useTemplatesForSpecialTeams = true}
	row:status(squadType)
	row:id{
		player.id,
		flag = player.flag,
		race = Faction.read(player.race),
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
		date = player.leavedate or player.inactivedate,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == SquadUtils.SquadType.FORMER then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	elseif squadType == SquadUtils.SquadType.INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create()
end

return CustomSquad
