---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local SquadAutoRefs = require('Module:SquadAuto/References')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local CustomSquad = {}
local HAS_NUMBER = false

local ExtendedSquadRow = Class.new(SquadRow)

function CustomSquad.header(self)
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow		:node(makeHeader('ID'))
					:node(makeHeader()) -- "Team Icon" (most commmonly used for loans)
	if HAS_NUMBER then
		headerRow 	:node(makeHeader('Number'))
	end
	headerRow		:node(makeHeader('Name'))
					:node(makeHeader('Position'))
					:node(makeHeader('Join Date'))
	if self.type == Squad.TYPE_FORMER then
		headerRow	:node(makeHeader('Leave Date'))
					:node(makeHeader('New Team'))
	elseif self.type == Squad.TYPE_INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end

	self.content:node(headerRow)

	return self
end

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
	self.lpdbData.role = args.role

	return self
end

function ExtendedSquadRow:number(args)
	mw.logObject(args)
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

function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	local index = 1
	while args['p' .. index] ~= nil or args[index] do
		local player = Json.parseIfString(args['p' .. index] or args[index])
		if player.number then
			HAS_NUMBER = true
			break
		end

		index = index + 1
	end

	squad.header = CustomSquad.header
	squad:header()

	while args['p' .. index] or args[index] do
		local player = Json.parseIfString(args['p' .. index] or args[index])

		squad:row(CustomSquad._playerRow(player, squad.type))

		index = index + 1
	end

	return squad:create()
end

function CustomSquad.runAuto(playerList, squadType)
	if Table.isEmpty(playerList) then
		return
	end

	local squad = Squad()
	squad:init(mw.getCurrentFrame())

	squad.type = squadType

	squad.header = CustomSquad.header
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
		player.team = player.thisTeam.role == 'Loan' and player.oldTeam.team

		player.newteam = player.newTeam.team
		player.newteamrole = player.newTeam.role
		player.newteamdate = player.newTeam.date

		squad:row(CustomSquad._playerRow(player, squad.type))
	end

	return squad:create()
end

function CustomSquad._playerRow(player, squadType)
	local row = ExtendedSquadRow(mw.getCurrentFrame(), player.role, player.number)

	row:id({
		(player.idleavedate or player.id),
		flag = player.flag,
		link = player.link,
		captain = player.captain,
		role = player.role,
		team = player.team,
	})
	if HAS_NUMBER then
		row:number{number = player.number}
	end
	row:name{name = player.name}
	row:position{role = player.role, position = player.position}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.TYPE_FORMER then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	elseif squadType == Squad.TYPE_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	return row:create(
		mw.title.getCurrentTitle().prefixedText .. '_' .. player.id .. '_' .. ReferenceCleaner.clean(player.joindate)
	)
end

return CustomSquad
