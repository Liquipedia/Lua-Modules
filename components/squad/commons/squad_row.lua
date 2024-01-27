---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Flags = require('Module:Flags')
local OpponentLib = require('Module:OpponentLibraries')
local Opponent = OpponentLib.Opponent
local OpponentDisplay = OpponentLib.OpponentDisplay
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Squad = require('Module:Squad')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

-- TODO: Decided on all valid types
-- TODO: Move to dedicated module
local VALID_TYPES = {'player', 'staff'}
local DEFAULT_TYPE = 'player'

local STATUS_MAPPING = {
	[Squad.TYPE_ACTIVE] = 'active',
	[Squad.TYPE_INACTIVE] = 'inactive',
	[Squad.TYPE_FORMER] = 'former',
	[Squad.TYPE_FORMER_INACTIVE] = 'former',
}

local ICON_CAPTAIN = '[[File:Captain Icon.png|18px|baseline|Captain|link=Category:Captains|alt=Captain'
	.. '|class=player-role-icon]]'
local ICON_SUBSTITUTE = '[[File:Substitution.png|18px|baseline|Sub|link=|alt=Substitution|class=player-role-icon]]'

local SquadRow = Class.new(
	function(self, options)
		self.content = mw.html.create('tr'):addClass('Player')
		self.options = options or {}

		self.lpdbData = {type = DEFAULT_TYPE}
	end)

SquadRow.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
	['passed away'] = 'Team/passed away',
}


function SquadRow:id(args)
	if String.isEmpty(args[1]) then
		return error('Something is off with your input!')
	end

	local cell = mw.html.create('td')
	cell:addClass('ID')

	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs(Table.merge(args, {type = Opponent.solo})),
		nil, {syncPlayer = true}
	)
	cell:tag('b'):node(OpponentDisplay.InlineOpponent{opponent = opponent})

	if String.isNotEmpty(args.captain) then
		cell:wikitext('&nbsp;' .. ICON_CAPTAIN)
		self.lpdbData.role = 'Captain'
	end

	if args.role == 'sub' then
		cell:wikitext('&nbsp;' .. ICON_SUBSTITUTE)
	end

	if String.isNotEmpty(args.name) then
		cell:tag('br'):done():tag('i'):tag('small'):wikitext(args.name)
		self.lpdbData.name = args.name
	end

	local teamNode = mw.html.create('td')
	if args.team and mw.ext.TeamTemplate.teamexists(args.team) then
		local date = String.nilIfEmpty(ReferenceCleaner.clean(args.date))
		teamNode:wikitext(mw.ext.TeamTemplate.teamicon(args.team, date))
		if args.teamrole then
			teamNode:css('text-align', 'center')
			teamNode:tag('div'):css('font-size', '85%'):tag('i'):wikitext(args.teamrole)
		end
	end

	self.content:node(cell)
	self.content:node(teamNode)

	self.lpdbData.id = args[1]
	self.lpdbData.nationality = Flags.CountryName(args.flag)
	self.lpdbData.link = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or args[1])


	return self
end

function SquadRow:name(args)
	local cell = mw.html.create('td')
	cell:addClass('Name')
	cell:tag('div'):addClass('MobileStuff'):wikitext('(')
	cell:wikitext(args.name)
	cell:tag('div'):addClass('MobileStuff'):wikitext(')')
	self.content:node(cell)

	self.lpdbData.name = args.name

	return self
end

function SquadRow:role(args)
	local cell = mw.html.create('td')
	-- The CSS class has this name, not a typo.
	cell:addClass('Position')

	if String.isNotEmpty(args.role) then
		cell:tag('div'):addClass('MobileStuff'):wikitext('Role:&nbsp;')
		cell:tag('i'):wikitext('(' .. args.role .. ')')
	end

	self.content:node(cell)

	self.lpdbData.role = args.role or self.lpdbData.role

	-- Set row background for certain roles
	local role = string.lower(args.role or '')

	if role == 'sub' then
		self.content:addClass('sub')
	elseif role:find('coach', 1, true) then
		self.content:addClass(role)
		self.content:addClass('roster-coach')
	end

	return self
end

function SquadRow:date(dateValue, cellTitle, lpdbColumn)
	local cell = mw.html.create('td')
	cell:addClass('Date')

	if String.isNotEmpty(dateValue) then
		cell:tag('div'):addClass('MobileStuffDate'):wikitext(cellTitle)
		cell:tag('div'):addClass('Date'):tag('i'):wikitext(dateValue)
	end
	self.content:node(cell)

	self.lpdbData[lpdbColumn] = ReferenceCleaner.clean(dateValue)

	return self
end

function SquadRow:newteam(args)
	local cell = mw.html.create('td')
	cell:addClass('NewTeam')

	if String.isNotEmpty(args.newteam) or String.isNotEmpty(args.newteamrole) then
		local mobileStuffDiv = mw.html.create('div'):addClass('MobileStuff')
			:tag('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'):done():wikitext('&nbsp;')
		cell:node(mobileStuffDiv)

		if String.isNotEmpty(args.newteam) then
			local newTeam = args.newteam
			if mw.ext.TeamTemplate.teamexists(newTeam) then
				local date = args.newteamdate or ReferenceCleaner.clean(args.leavedate)
				cell:wikitext(mw.ext.TeamTemplate.team(newTeam, date))

				self.lpdbData.newteam = mw.ext.TeamTemplate.teampage(newTeam)
				self.lpdbData.newteamtemplate = mw.ext.TeamTemplate.raw(newTeam, date).templatename
			elseif self.options.useTemplatesForSpecialTeams then
				local newTeamTemplate = SquadRow.specialTeamsTemplateMapping[newTeam]
				if newTeamTemplate then
					cell:wikitext(Template.safeExpand(mw.getCurrentFrame(), newTeamTemplate))
				end
			end

			if String.isNotEmpty(args.newteamrole) then
				cell:wikitext('&nbsp;'):tag('i'):tag('small'):wikitext('(' .. args.newteamrole .. ')')
			end
		elseif not self.options.useTemplatesForSpecialTeams and String.isNotEmpty(args.newteamrole) then
			cell:tag('div'):addClass('NewTeamRole'):wikitext(args.newteamrole)
		end
	end

	self.content:node(cell)

	return self
end

function SquadRow:setType(type)
	type = type:lower()
	if Table.includes(VALID_TYPES, type) then
		self.lpdbData.type = type
	end
	return self
end

function SquadRow:status(status)
	self.lpdbData.status = STATUS_MAPPING[status]
	return self
end

function SquadRow:setExtradata(extradata)
	self.lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata)
	return self
end

function SquadRow:create(objectName)
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		mw.ext.LiquipediaDB.lpdb_squadplayer(objectName, self.lpdbData)
	end

	return self.content
end

return SquadRow
