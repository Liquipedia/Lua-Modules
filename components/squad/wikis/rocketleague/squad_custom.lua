---
-- @Liquipedia
-- wiki=rocketleague
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

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title():header()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args['p' .. index] or args[index])
	end)

	Array.forEach(players, function(player)
		local row = SquadRow{useTemplatesForSpecialTeams = true}
		row:status(squad.type)
		row:id({
			player.id,
			flag = player.flag,
			link = player.link,
			captain = player.captain,
			role = player.role,
			team = player.team,
			date = player.leavedate or player.inactivedate or player.leavedate,
		})
			:name({name = player.name})
			:role({role = player.role})
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.SquadTypes.FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam({
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			})
		elseif squad.type == Squad.SquadTypes.INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(player.link or player.id)
		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText .. '_' .. link .. '_' .. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))
	end)

	return squad:create()
end

return CustomSquad
