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

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}

---@param self Squad
---@return Squad
function CustomSquad.header(self)
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow:node(makeHeader('ID'))
		:node(makeHeader())
		:node(makeHeader('Name'))
		:node(makeHeader('Position'))
		:node(makeHeader('Join Date'))
	if self.type == Squad.SquadType.FORMER then
		headerRow:node(makeHeader('Leave Date'))
			:node(makeHeader('New Team'))
	elseif self.type == Squad.SquadType.INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end

	self.content:node(headerRow)

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
	local cell = mw.html.create('td')
	cell:addClass('Position')

	if String.isNotEmpty(args.position) or String.isNotEmpty(args.role) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(args.position) then
			cell:wikitext(args.position)
			if String.isNotEmpty(args.role) then
				cell:wikitext('&nbsp;(' .. args.role .. ')')
			end
		elseif String.isNotEmpty(args.role) then
			cell:wikitext(args.role)
		end
	end

	self.content:node(cell)

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

	local squad = Squad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad.header = CustomSquad.header
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
