---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Squad = require('Module:Squad')
local SquadRow = require('Module:Squad/Row')
local SquadAutoRefs = require('Module:SquadAuto/References')
local Table = require('Module:Table')
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

	headerRow:node(makeHeader('ID'))
			:node(makeHeader())
			:node(makeHeader('Name'))
			:node(makeHeader()) -- "Role"
			:node(makeHeader('Join Date'))
	if self.type == Squad.TYPE_INACTIVE or self.type == Squad.TYPE_FORMER_INACTIVE then
		headerRow:node(makeHeader('Inactive Date'))
	end
	if self.type == Squad.TYPE_FORMER or self.type == Squad.TYPE_FORMER_INACTIVE then
		headerRow:node(makeHeader('Leave Date'))
				:node(makeHeader('New Team'))
	end

	self.content:node(headerRow)

	return self
end

function CustomSquad.run(frame)
	local squad = Squad()

	squad:init(frame):title()

	local args = squad.args

	if squad.type == Squad.TYPE_FORMER then
		local index = 1
		while args['p' .. index] or args[index] do
			local player = Json.parseIfString(args['p' .. index] or args[index])
			if player.inactivedate then
				squad.type = Squad.TYPE_FORMER_INACTIVE
				break
			end

			index = index + 1
		end
	end

	squad.header = CustomSquad.header
	squad:header()

	local index = 1
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
	local row = SquadRow(mw.getCurrentFrame(), player.role, {useTemplatesForSpecialTeams = true})

	row:id{
		player.id,
		flag = player.flag,
		link = player.link,
		captain = player.captain or player.igl,
		role = player.role,
		team = player.team,
		teamrole = player.teamrole,
	}
	row:name{name = player.name}
	row:role{role = player.role}
	row:date(player.joindate, 'Join Date:&nbsp;', 'joindate')

	if squadType == Squad.TYPE_INACTIVE or squadType == Squad.TYPE_FORMER_INACTIVE then
		row:date(player.inactivedate, 'Inactive Date:&nbsp;', 'inactivedate')
	end

	if squadType == Squad.TYPE_FORMER or squadType == Squad.TYPE_FORMER_INACTIVE then
		row:date(player.leavedate, 'Leave Date:&nbsp;', 'leavedate')
		row:newteam{
			newteam = player.newteam,
			newteamrole = player.newteamrole or player.newrole,
			newteamdate = player.newteamdate,
			leavedate = player.leavedate
		}
	end

	return row:create(
		Variables.varDefault(
			'squad_name',
			mw.title.getCurrentTitle().prefixedText
		)
		.. '_' .. player.id .. '_'
		.. ReferenceCleaner.clean(player.joindate)
	)
end

return CustomSquad
