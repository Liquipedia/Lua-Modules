---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Widget = require('Module:Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}
local ExtendedSquad = Class.new(Squad)

---@return self
function ExtendedSquad:header()
	local headerRow = Widget.TableRow{classes = 'HeaderRow', css = {['font-weight'] = 'bold'}}

	local cellArgs = {classes = 'divCell'}
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('ID'))
	headerRow:addCell(Widget.TableCell(cellArgs)) -- "Team Icon" (most commmonly used for loans)
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('Name'))
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('Position'))
	headerRow:addCell(Widget.TableCell(cellArgs):addContent('Join Date'))

	if self.type == Squad.SquadType.FORMER then
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('Leave Date'))
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('New Team'))
	elseif self.type == Squad.SquadType.INACTIVE then
		headerRow:addCell(Widget.TableCell(cellArgs):addContent('Inactive Date'))
	end

	self.content:addRow(headerRow)

	return self
end

---@class ArenaofvalorSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@param args table
---@return self
function ExtendedSquadRow:position(args)
	local cell = Widget.TableCell
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
	local squad = ExtendedSquad():init(frame):title():header()

	local players = Array.mapIndexes(function(index)
		return Json.parseIfString(squad.args[index])
	end)

	Array.forEach(players, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param playerList table[]
---@param squadType integer
---@return Html?
function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = ExtendedSquad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad:title():header()

	for _, player in pairs(playerList) do
		--Get Reference(s)
		local joinReference = SquadAutoRefs.useReferences(player.joindateRef, player.joindate)
		local leaveReference = SquadAutoRefs.useReferences(player.leavedateRef, player.leavedate)

		-- Map between formats
		player.joindate = (player.joindatedisplay or player.joindate) .. ' ' .. joinReference
		player.leavedate = (player.leavedatedisplay or player.leavedate) .. ' ' .. leaveReference
		player.inactivedate = player.leavedate

		player.link = player.page
		player.role = player.thisTeam.role
		player.position = player.thisTeam.position
		player.team = player.thisTeam.role == 'Loan' and player.oldTeam.team

		player.newteam = player.newTeam.team
		player.newteamrole = player.newTeam.role
		player.newteamdate = player.newTeam.date

		squad:row(CustomSquad._playerRow(player, squad.type))
	end

	return squad:create()
end

---@param player table
---@param squadType integer
---@return Html
function CustomSquad._playerRow(player, squadType)
	local row = ExtendedSquadRow()

	row:status(squadType)
	row:id({
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
		date = player.leavedate or player.inactivedate or player.leavedate,
	})
	row:name{name = player.name}
	row:position{role = player.role, position = player.position}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.SquadType.FORMER then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	elseif squadType == Squad.SquadType.INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
		.. (player.role and '_' .. player.role or '')
		.. '_' .. squadType
	)
end

return CustomSquad
