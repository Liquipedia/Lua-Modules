---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}
local CustomInjector = Class.new(SquadUtils.positionHeaderInjector())

local LANG = mw.getContentLanguage()

function CustomInjector:parse(id, widgets)
	if id == 'header_inactive' then
		table.insert(widgets, Widget.TableCellNew{content = {'Active Team'}, header = true})
	end

	return self._base:parse(id, widgets)
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow, CustomInjector)
end

function CustomSquad._playerRow(player, squadType)
	local row = SquadRow()
	row:status(squadType)
	row:id{
		player.id,
		flag = player.flag,
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
		teamrole = player.teamrole,
		date = player.leavedate or player.inactivedate,
	}
	row:name{name = player.name}
	row:position{position = player.position, role = player.role and LANG:ucfirst(player.role) or nil}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
		row:newteam{
			newteam = player.activeteam,
			newteamrole = player.activeteamrole,
			newteamdate = player.inactivedate
		}
	end
	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	end

	return row:create(SquadUtils.defaultObjectName(player, squadType))
end

return CustomSquad
