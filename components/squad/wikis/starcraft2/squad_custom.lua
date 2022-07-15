---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local CleanRace = require('Module:CleanRace')

SquadRow.specialTeamsTemplateMapping = {
	retirement = 'Team/retired',
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	military = 'Team/military',
}

local _FACTION1 = {
	['p'] = 'Protoss', ['pt'] = 'Protoss', ['pz'] = 'Protoss',
	['t'] = 'Terran', ['tp'] = 'Terran', ['tz'] = 'Terran',
	['z'] = 'Zerg', ['zt'] = 'Zerg', ['zp'] = 'Zerg',
	['r'] = 'Random', ['a'] = 'All'
}
local _FACTION2 = {
	['pt'] = 'Terran', ['pz'] = 'Zerg',
	['tp'] = 'Protoss', ['tz'] = 'Zerg',
	['zt'] = 'Terran', ['zp'] = 'Protoss'
}

local CustomSquad = {}

function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title():header()

	local args = squad.args

	local isFormer = squad.type == Squad.TYPE_FORMER
	local isInactive = squad.type == Squad.TYPE_INACTIVE
	local isMainSquad = Logic.readBool(args.main)
	local squadName = args.squad or mw.title.getCurrentTitle().prefixedText
	local status = (isFormer and 'former')
		or (isInactive and 'inactive')
		or (isMainSquad and 'main')
		or 'active'

	local index = 1
	while args['p' .. index] or args[index] do

		local player = Json.parseIfString(args['p' .. index] or args[index])
		player.race = string.lower(player.race)
		player.race = CleanRace[player.race] or player.race
		local row = SquadRow(frame, player.role, {useTemplatesForSpecialTeams = true})
		row	:id({
				player.id,
				flag = player.flag,
				race = player.race,
				link = player.link,
				captain = player.captain,
				role = player.role,
				team = player.team,
			})
			:name({name = player.name})
			:role({role = player.role})
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if isFormer then
			if String.isEmpty(player.newteam) then
				if Logic.readBool(player.retired) then
					player.newteam = 'retired'
				elseif Logic.readBool(player.military) then
					player.newteam = 'military'
				end
			end

			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam({
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			})
		elseif isInactive then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end

		row.lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			faction = _FACTION1[player.race],
			faction2 = _FACTION2[player.race],
			squadname = squadName,
			status = status
		})

		squad:row(row:create(
			squadName .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
		))

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
