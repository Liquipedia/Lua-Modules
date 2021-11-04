local Squad = require('Module:VoganRL/Squad')
local SquadRow = require('Module:VoganRL/Squad/Row')
local Json = require('Module:Json')
local Logic = require('Module:Logic')


local CustomSquad = {}

function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title()

	local status = Logic.readBool(squad.args.active or 'true') == true
		and Squad.TYPE_ACTIVE or Squad.TYPE_FORMER
	squad:header(status)

	local args = squad.args

	local index = 1
	while args['p' .. index] ~= nil do
		local player = Json.parseIfString(args['p' .. index])
		local row = SquadRow(frame, player.role)
		row:id({
			player.id,
			flag = player.flag,
			link = player.link,
			captain = player.captain,
			role = player.role,
		})

		row	:name({name = player.name})
			:role({role = player.role})
			:date(player.joindate)

		if status == Squad.TYPE_FORMER then
			row:date(player.leavedate)
		end

		squad:row(row:create())

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
