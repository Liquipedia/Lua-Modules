---
-- @Liquipedia
-- wiki=overwatch
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

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadAutoRefs = Lua.import('Module:SquadAuto/References')

local CustomSquad = {}
local HAS_NUMBER = false

---@class OverwatchSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

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
		:node(makeHeader()) -- "Team Icon" (most commmonly used for loans)
	if HAS_NUMBER then
		headerRow:node(makeHeader('Number'))
	end
	headerRow:node(makeHeader('Name'))
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

---@param args table
---@return self
function ExtendedSquadRow:number(args)
	local cell = mw.html.create('td')
	cell:addClass('Number')

	if String.isNotEmpty(args.number) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Number:&nbsp;'))

		if String.isNotEmpty(args.number) then
			cell:wikitext(args.number)
		end
	end

	self.content:node(cell)

	self.lpdbData.number = args.number

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	local players = Array.mapIndexes(function(index)
		local player = Json.parseIfString(args[index])
		if type(player) == 'table' and player.number then
			HAS_NUMBER = true
		end
		return player
	end)

	squad.header = CustomSquad.header
	squad:header()

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

	local squad = Squad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad.header = CustomSquad.header
	squad:title():header()

	Array.forEach(playerList, function(player)
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
	end)

	return squad:create()
end

---@param player table
---@param squadType integer
---@return WidgetTableRow
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
	if HAS_NUMBER then
		row:number{number = player.number}
	end
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
