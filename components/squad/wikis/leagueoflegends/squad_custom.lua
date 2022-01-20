---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local Json = require('Module:Json')
local Variables = require('Module:Variables')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Class = require('Module:Class')
local String = require('Module:String')

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
					:node(makeHeader('Name'))
					:node(makeHeader())
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

local ExtendedSquadRow = Class.new(SquadRow)

function ExtendedSquadRow:position(args)
	local cell = mw.html.create('td')
	cell:addClass('Position')

	if not String.isEmpty(args.position) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))
		cell:wikitext('' .. args.position .. '')
	end

	self.content:node(cell)

	self.lpdbData['position'] = args.position

	return self
end

function CustomSquad.run(frame)
	local squad = Squad()

	-- It looks like we cannot extend Squad because overwriting
	-- the function makes the other functions inaccessible?
	-- TODO: investigate
	squad.header = CustomSquad.header
	squad:init(frame):title():header()

	local args = squad.args

	local index = 1
	while args['p' .. index] ~= nil or args[index] do
		local player = Json.parseIfString(args['p' .. index] or args[index])
		local row = ExtendedSquadRow(frame, player.role)
		row	:id({
				player.id,
				flag = player.flag,
				link = player.link,
				captain = player.captain,
				role = player.role,
				team = player.team,
			})
			:name({name = player.name})
			:role({role = player.role})
			:position({position = player.position})
			:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

		if squad.type == Squad.TYPE_FORMER then
			row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
			row:newteam({
				newteam = player.newteam,
				newteamrole = player.newteamrole,
				newteamdate = player.newteamdate,
				leavedate = player.leavedate
			})
		elseif squad.type == Squad.TYPE_INACTIVE then
			row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
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
