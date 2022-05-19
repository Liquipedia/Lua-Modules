---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local CustomSquad = {}

function CustomSquad.header(self)
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

	headerRow	:node(makeHeader('ID'))
			:node(makeHeader())
			:node(makeHeader('Name'))
			:node(makeHeader('Position'))
			:node(makeHeader('Join Date'))
	if self.type == Squad.TYPE_INACTIVE or self.type == Squad.TYPE_FORMER_INACTIVE then
		headerRow	:node(makeHeader('Inactive Date'))
				:node(makeHeader('Last Active Team'))
	end
	if self.type == Squad.TYPE_FORMER or self.type == Squad.TYPE_FORMER_INACTIVE then
		headerRow	:node(makeHeader('Leave Date'))
				:node(makeHeader('New Team'))
	end

	self.content:node(headerRow)

	return self
end

local ExtendedSquadRow = Class.new(SquadRow)

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

	self.lpdbData['position'] = args.position
	self.lpdbData['role'] = args.role

	return self
end

function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	if squad.type == Squad.TYPE_FORMER then
		local index = 1
		while args['p' .. index] ~= nil or args[index] or squad.type ~= Squad.TYPE_FORMER_INACTIVE do
			local player = Json.parseIfString(args['p' .. index] or args[index])
			if player.inactivedate then
				squad.type = Squad.TYPE_FORMER_INACTIVE
			end

			index = index + 1
		end
	end

	squad.header = CustomSquad.header
	squad:header()

	local index = 1
	while args['p' .. index] ~= nil or args[index] do
		local player = Json.parseIfString(args['p' .. index] or args[index])
		local row = ExtendedSquadRow(frame, player.role)
		row	:id{
				player.id,
				flag = player.flag,
				link = player.link,
				captain = player.captain,
				role = player.role,
				team = player.team,
				teamrole = player.teamrole,
			}
			:name{name = player.name}
			:position{position = player.position, role = mw.language.new('en'):ucfirst(player.role or '')}
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.TYPE_INACTIVE or squad.type == Squad.TYPE_FORMER_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
			row:newteam{
				newteam = player.activeteam,
				newteamrole = player.activeteamrole,
				newteamdate = player.inactivedate
			}
		end
		if squad.type == Squad.TYPE_FORMER or squad.type == Squad.TYPE_FORMER_INACTIVE then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam{
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			}
		end

		squad:row(row:create(
			Variables.varDefault('squad_name',
			mw.title.getCurrentTitle().prefixedText) ..
				'_' .. player.id .. '_' ..
				ReferenceCleaner.clean(player.joindate)
		))

		index = index + 1
	end

	return squad:create()
end

return CustomSquad
