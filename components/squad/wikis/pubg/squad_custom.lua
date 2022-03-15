---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local Json = require('Module:Json')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')

local CustomSquad = {}

function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title():header()

	local args = squad.args

	local index = 1
	while args['p' .. index] ~= nil or args[index] do
		local player = Json.parseIfString(args['p' .. index] or args[index])
		local row = SquadRow(frame, player.role, {useTemplatesForSpecialTeams = true})
		row	:id({
				player.id,
				flag = player.flag,
				link = player.link,
				captain = player.captain,
				role = player.role,
				team = player.team,
			})
			:name({name = player.name})
			:role({role = player.role})
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.TYPE_FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam({
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			})
		elseif squad.type == Squad.TYPE_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		squad:row(row:create(
			Variables.varDefault('squad_name',
			mw.title.getCurrentTitle().prefixedText) .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
		))

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
