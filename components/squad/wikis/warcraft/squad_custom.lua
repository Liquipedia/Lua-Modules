---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad():init(frame):title():header()

	local players = SquadUtils.parsePlayers(squad.args)

	Array.forEach(players, function(player)
		local row = SquadRow{useTemplatesForSpecialTeams = true}
		row:status(squad.type)
		row:id{
			player.id,
			flag = player.flag,
			race = Faction.read(player.race),
			link = player.link,
			captain = player.captain,
			role = player.role,
			team = player.team,
			date = player.leavedate or player.inactivedate or player.leavedate,
		}
		row:name{name = player.name}
		row:role{role = player.role}
		row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == SquadUtils.SquadType.FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		elseif squad.type == SquadUtils.SquadType.INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		squad:row(row:create(SquadUtils.defaultObjectName(player, squad.type)))
	end)

	return squad:create()
end

return CustomSquad
