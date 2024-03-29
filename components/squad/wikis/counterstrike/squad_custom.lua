---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')

local CustomSquad = {}

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(args[index])
	end)

	---@param player table
	---@return boolean
	local hasInactive = function(player)
		return Logic.isNotEmpty(player.inactivedate)
	end

	if squad.type == Squad.SquadType.FORMER and Array.any(players, hasInactive) then
		squad.type = Squad.SquadType.FORMER_INACTIVE
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

		if squad.type == Squad.SquadType.INACTIVE or squad.type == Squad.SquadType.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		end
		if squad.type == Squad.SquadType.FORMER or squad.type == Squad.SquadType.FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole or player.newrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		squad:row(row:create(
			mw.title.getCurrentTitle().prefixedText ..
			'_' .. player.id .. '_' ..
			ReferenceCleaner.clean(player.joindate) ..
			(player.role and '_' .. player.role or '')
			.. '_' .. squad.type
		))
	end)

	return squad:create()
end

return CustomSquad
