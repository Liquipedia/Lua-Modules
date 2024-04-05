---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

local CustomSquad = {}
local CustomInjector = Class.new(Injector)

local LANG = mw.getContentLanguage()

function CustomInjector:parse(id, widgets)
	if id == 'header_role' then
		return {Widget.TableCell{}:addContent('Position')}
	elseif id == 'header_inactive' then
		table.insert(widgets, Widget.TableCell{}:addContent('Active Team'))
	end

	return widgets
end

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:position(args)
	local cell = Widget.TableCell{}
	cell:addClass('Position')

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		cell:addContent(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			cell:addContent(args.position)
			if String.isNotEmpty(args.role) then
				cell:addContent('&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			cell:addContent(args.role)
		end
	end

	self.content:addCell(cell)

	self.lpdbData.position = args.position
	self.lpdbData.role = args.role or self.lpdbData.role

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad():init(frame, CustomInjector()):title()

	local players = SquadUtils.parsePlayers(squad.args)

	if squad.type == SquadUtils.SquadType.FORMER and SquadUtils.anyInactive(players) then
		squad.type = SquadUtils.SquadType.FORMER_INACTIVE
	end

	squad:header()

	Array.forEach(players, function(player)
		local row = ExtendedSquadRow()
		row:status(squad.type)
		row:id{
			player.id,
			flag = player.flag,
			link = player.link,
			captain = player.captain,
			role = player.role,
			team = player.team,
			teamrole = player.teamrole,
			date = player.leavedate or player.inactivedate or player.leavedate,
		}
			:name{name = player.name}
			:position{position = player.position, role = player.role and LANG:ucfirst(player.role) or nil}
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == SquadUtils.SquadType.INACTIVE or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			row:newteam{
				newteam = player.activeteam,
				newteamrole = player.activeteamrole,
				newteamdate = player.inactivedate
			}
		end
		if squad.type == SquadUtils.SquadType.FORMER or squad.type == SquadUtils.SquadType.FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		squad:row(row:create(SquadUtils.defaultObjectName(player, squad.type)))
	end)

	return squad:create()
end

return CustomSquad
