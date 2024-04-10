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
		return {Widget.TableCellNew{content = {'Position'}, header = true}}
	elseif id == 'header_inactive' then
		table.insert(widgets, Widget.TableCellNew{content = {'Active Team'}, header = true})
	end

	return widgets
end

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:position(args)
	local content = {}

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		table.insert(content, mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			table.insert(content, args.position)
			if String.isNotEmpty(args.role) then
				table.insert(content, '&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			table.insert(content, args.role)
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = content,
	})

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
