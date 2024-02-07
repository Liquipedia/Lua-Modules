---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

--only for legacy reasons
SquadRow.specialTeamsTemplateMapping.retirement = 'Team/retired'

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()
	squad:init(frame):title():header()

	local args = squad.args

	local isFormer = squad.type == Squad.SquadType.FORMER
	local isInactive = squad.type == Squad.SquadType.INACTIVE
	local isMainSquad = Logic.readBool(args.main)
	local squadName = args.squad or mw.title.getCurrentTitle().prefixedText
	local status = (isFormer and 'former')
		or (isInactive and 'inactive')
		or (isMainSquad and 'main')
		or 'active'

	local players = Array.mapIndexes(function(index)
		local player = Json.parseIfString(args[index])
		if not player then return player end
		player.faction = Faction.read(player.race)
		if isFormer then
			player.newteam = String.nilIfEmpty(player.newteam) or
				Logic.readBool(player.retired) and 'retired' or
				Logic.readBool(player.military) and 'military' or nil
		end
		return player
	end)

	Array.forEach(players, function(player)
		local row = SquadRow{useTemplatesForSpecialTeams = true}
			:status(squad.type)
			:id({
				player.id,
				flag = player.flag,
				race = player.faction,
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

		row:setExtradata{
			faction = player.faction,
			squadname = squadName,
			status = status,
		}

		squad:row(row:create(
			squadName .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
			.. (player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))
	end)

	return squad:create()
end

return CustomSquad
