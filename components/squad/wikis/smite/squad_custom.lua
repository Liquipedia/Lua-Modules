---
-- @Liquipedia
-- wiki=smite
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

local CustomSquad = {}
local CustomInjector = Class.new(Injector)

function CustomInjector:parse(id, widgets)
	if id == 'header_role' then
		return {
			Widget.TableCellNew{content = {'Position'}, header = true}
		}
	end

	return widgets
end

---@param frame Frame
function CustomSquad.run(frame)
	error('SMITE wiki doesn\'t support manual Squad Tables')
end

---@class SmiteSquadRow: SquadRow
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

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = Squad():init({type = squadType}, CustomInjector()):title():header()

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRowNew
function CustomSquad._playerRow(player, squadType)
	local row = ExtendedSquadRow()

	--Get Reference(s)
	local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
	local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

	local joinText = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
	local leaveText = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference

	row:status(squadType)
	row:id({
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.page,
		captain = player.captain,
		role = player.thisTeam.role,
		team = player.thisTeam.role == 'Loan' and player.oldTeam.team,
		date = player.leavedate or player.inactivedate or player.leavedate,
	})
	row:name({name = player.name})
	row:position{role = player.thisTeam.role, position = player.thisTeam.position}
	row:date(joinText, 'Join Date:&nbsp;', 'joindate')

	if squadType == SquadUtils.SquadType.FORMER then
		row:date(leaveText, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam({
			newteam = player.newTeam.team,
			newteamrole = player.newTeam.role,
			newteamdate = player.newTeam.date,
			leavedate = player.newTeam.date
		})
	elseif squadType == SquadUtils.SquadType.INACTIVE then
		row:date(leaveText, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(SquadUtils.defaultObjectName(player, squadType))
end

return CustomSquad
