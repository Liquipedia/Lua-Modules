---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad():init(frame):title()

	local players = SquadUtils.parsePlayers(squad.args)

	if squad.type == SquadUtils.SquadType.FORMER and SquadUtils.anyInactive(players) then
		squad.type = SquadUtils.SquadType.FORMER_INACTIVE
	end

	squad:header()

	Array.forEach(players, function(player)
		local row = SquadRow{useTemplatesForSpecialTeams = true}
		row:status(squad.type)
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
			:name{name = player.name}
			:role{role = player.role}
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == SquadUtils.SquadType.INACTIVE or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end
		if squad.type == SquadUtils.SquadType.FORMER or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole or player.newrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		squad:row(row:create())
	end)

	return squad:create()
end

return CustomSquad
