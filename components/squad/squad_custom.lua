local Squad = require('Module:VoganRL/Squad')
local SquadRow = require('Module:VoganRL/Squad/Row')
local Json = require('Module:Json')


local CustomSquad = {}

function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title():header()

	local args = squad.args

	local index = 1
	while args['p' .. index] ~= nil do
		local player = Json.parseIfString(args['p' .. index])
		local row = SquadRow(frame)
		row:id({
			player.id,
			flag = player.flag,
			link = player.link,
			captain = player.captain,
			role = player.role,
		})

		row	:name({name = player.name})
			:role({role = player.role})
			:joinDate({joindate = player.joindate})

		squad:row(row:create())

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
