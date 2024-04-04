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
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}
local ExtendedSquad = Class.new(Squad)

---@return self
function ExtendedSquad:header()
	local isInactive = self.type == Squad.SquadType.INACTIVE or self.type == Squad.SquadType.FORMER_INACTIVE
	local isFormer = self.type == Squad.SquadType.FORMER or self.type == Squad.SquadType.FORMER_INACTIVE
	local cellArgs = {classes = {'divCell'}}
	table.insert(self.rows, Widget.TableRow{
		classes = {'HeaderRow'},
		css = {['font-weight'] = 'bold'},
		cells = {
			Widget.TableCell(cellArgs):addContent('ID'),
			Widget.TableCell(cellArgs), -- "Team Icon" (most commmonly used for loans)
			Widget.TableCell(cellArgs):addContent('Name'),
			Widget.TableCell(cellArgs):addContent('Position'),
			Widget.TableCell(cellArgs):addContent('Join Date'),
			isInactive and Widget.TableCell(cellArgs):addContent('Inactive Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('Leave Date') or nil,
			isFormer and Widget.TableCell(cellArgs):addContent('New Team') or nil,
		}
	})

	return self
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

	Array.forEach(playerList, function(player)
		squad:row(CustomSquad._playerRow(player, squad.type))
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRow
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

	if squadType == Squad.SquadType.FORMER then
		row:date(leaveText, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam({
			newteam = player.newTeam.team,
			newteamrole = player.newTeam.role,
			newteamdate = player.newTeam.date,
			leavedate = player.newTeam.date
		})
	elseif squadType == Squad.SquadType.INACTIVE then
		row:date(leaveText, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText .. '_' .. player.id .. '_'
		.. player.joindate .. (player.role and '_' .. player.role or '')
		.. '_' .. squadType
	)
end

return CustomSquad
