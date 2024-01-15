---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

SquadRow.specialTeamsTemplateMapping = {
	retirement = 'Team/retired',
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	military = 'Team/military',
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
		local row = SquadRow{useTemplatesForSpecialTeams = true}
		row:status(squad.type)
		row:id({
			player.id,
			flag = player.flag,
			race = Faction.read(player.race),
			link = player.link,
			captain = player.captain,
			role = player.role,
			team = player.team,
			date = player.leavedate or player.inactivedate or player.leavedate,
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

		local factions = Faction.readMultiFaction(player.race, {alias = false})

		row:setExtradata({
			faction = Faction.toName(factions[1]),
			faction2 = Faction.toName(factions[2]),
			faction3 = Faction.toName(factions[3]),
			squadname = squadName,
			status = status
		})

		squad:row(row:create(
			squadName .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
