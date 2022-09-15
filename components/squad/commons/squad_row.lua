---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Player = require('Module:Player')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Table = require('Module:Table')

-- TODO: Decided on all valid types
-- TODO: Move to dedicated module
local _VALID_TYPES = {'player', 'staff'}
local _DEFAULT_TYPE = 'player'


local _ICON_CAPTAIN = '[[image:Captain Icon.png|18px|baseline|Captain|link=Category:Captains|alt=Captain|class=show-when-light-mode]]'
			.. '[[image:Captain Icon darkmode.png|18px|baseline|Captain|link=Category:Captains|alt=Captain|class=show-when-dark-mode]]'
local _ICON_SUBSTITUTE = '[[image:Substitution.png|18px|baseline|Sub|link=|alt=Substitution|class=show-when-light-mode]]'
			.. [[image:Substitution darkmode.png|18px|baseline|Sub|link=|alt=Substitution|class=show-when-dark-mode]]'

local SquadRow = Class.new(
	function(self, frame, role, options)
		self.frame = frame
		self.content = mw.html.create('tr'):addClass('Player')
		self.options = options or {}

		role = string.lower(role or '')

		if role == 'sub' then
			self.content:addClass('sub')
		elseif role == 'coach' then
			self.content:addClass('coach')
			self.content:addClass('roster-coach')
		elseif role == 'coach/manager' then
			self.content:addClass('coach/manager')
			self.content:addClass('roster-coach')
		elseif role == 'coach/substitute' then
			self.content:addClass('coach/substitute')
			self.content:addClass('roster-coach')
		end

		self.lpdbData = {}
		self.lpdbData.type = _DEFAULT_TYPE
	end)

SquadRow.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
}


function SquadRow:id(args)
	if String.isEmpty(args[1]) then
		return error('Something is off with your input!')
	end

	local cell = mw.html.create('td')
	cell:addClass('ID')

	args['noclean'] = true
	cell:wikitext('\'\'\'' .. Player._player(args) .. '\'\'\'')
	args['noclean'] = nil

	if String.isNotEmpty(args.captain) then
		cell:wikitext('&nbsp;' .. _ICON_CAPTAIN)
	end

	if args.role == 'sub' then
		cell:wikitext('&nbsp;' .. _ICON_SUBSTITUTE)
	end

	local teamNode = mw.html.create('td')
	if mw.ext.TeamTemplate.teamexists(string.lower(args.team or '')) then
		teamNode:wikitext(mw.ext.TeamTemplate.teamicon(args.team:lower()))
		if args.teamrole then
			teamNode:css('text-align', 'center')
			teamNode:tag('div'):css('font-size', '85%'):wikitext('(\'\''.. args.teamrole ..'\'\')')
		end
	end

	self.content:node(cell)
	self.content:node(teamNode)

	self.lpdbData['id'] = args[1]
	self.lpdbData['nationality'] = Flags.CountryName(args.flag)
	self.lpdbData['link'] = mw.ext.TeamLiquidIntegration.resolve_redirect(args.link or args[1])


	return self
end

function SquadRow:name(args)
	local cell = mw.html.create('td')
	cell:addClass('Name')
	cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('('))
	cell:wikitext(args.name)
	cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext(')'))
	self.content:node(cell)

	self.lpdbData['name'] = args.name

	return self
end

function SquadRow:role(args)
	local cell = mw.html.create('td')
	-- The CSS class has this name, not a typo.
	cell:addClass('Position')

	if String.isNotEmpty(args.role) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Role:&nbsp;'))
		cell:wikitext('\'\'(' .. args.role .. ')\'\'')
	end

	self.content:node(cell)

	self.lpdbData['role'] = args.role

	return self
end

function SquadRow:date(dateValue, cellTitle, lpdbColumn)
	local cell = mw.html.create('td')
	cell:addClass('Date')

	cell:node(mw.html.create('div'):addClass('MobileStuffDate'):wikitext(cellTitle))

	if String.isNotEmpty(dateValue) then
		cell:node(mw.html.create('div'):addClass('Date'):wikitext('\'\'' .. dateValue .. '\'\''))
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
		mobileStuffDiv	:node(mw.html.create('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'))
						:wikitext('&nbsp;')
		cell:node(mobileStuffDiv)

		if String.isNotEmpty(args.newteam) then
			local newTeam = args.newteam:lower()
			if mw.ext.TeamTemplate.teamexists(newTeam) then
				local date = args.newteamdate or ReferenceCleaner.clean(args.leavedate)
				cell:wikitext(mw.ext.TeamTemplate.team(newTeam, date))

				self.lpdbData['newteam'] = mw.ext.TeamTemplate.teampage(newTeam)
				self.lpdbData['newteamtemplate'] = mw.ext.TeamTemplate.raw(newTeam, date).templatename
			elseif self.options.useTemplatesForSpecialTeams then
				local newTeamTemplate = SquadRow.specialTeamsTemplateMapping[newTeam]
				if newTeamTemplate then
					cell:wikitext(Template.safeExpand(mw.getCurrentFrame(), newTeamTemplate))
				end
			end

			if String.isNotEmpty(args.newteamrole) then
				cell:wikitext('&nbsp;\'\'<small>(' .. args.newteamrole .. ')</small>\'\'')
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
	if Table.includes(_VALID_TYPES, type) then
		self.lpdbData.type = type
	end
	return self
end

function SquadRow:addToLpdb(lpdbData)
	return lpdbData
end

function SquadRow:create(id)
	self.lpdbData = self:addToLpdb(self.lpdbData)
	mw.ext.LiquipediaDB.lpdb_squadplayer(id, self.lpdbData)
	return self.content
end

return SquadRow
