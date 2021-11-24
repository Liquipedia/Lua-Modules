local Class = require('Module:Class')
local String = require('Module:String')
local Player = require('Module:Player')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Template = require('Module:Template')

local _ICON_CAPTAIN = '[[image:Captain Icon.png|18px|baseline|Captain|link=Category:Captains|alt=Captain]]'
local _ICON_SUBSTITUTE = '[[image:Substitution.svg|18px|baseline|Sub|link=|alt=Substitution]]'

local _COLOR_BACKGROUND_COACH = '#e5e5e5'

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
			self.content:css('background-color', _COLOR_BACKGROUND_COACH)
		elseif role == 'coach/manager' then
			self.content:addClass('coach/manager')
			self.content:css('background-color', _COLOR_BACKGROUND_COACH)
		elseif role == 'coach/substitute' then
			self.content:addClass('coach/substitute')
			self.content:css('background-color', _COLOR_BACKGROUND_COACH)
		end
	end)

SquadRow.specialTeamsTemplateMapping = {
	retired = 'Team/retired',
	inactive = 'Team/inactive',
}


function SquadRow:id(args)
	local cell = mw.html.create('td')
	cell:addClass('ID')
	cell:wikitext('\'\'\'' .. Player._player(args) .. '\'\'\'')

	if not String.isEmpty(args.captain) then
		cell:wikitext(_ICON_CAPTAIN)
	end

	if args.role == 'sub' then
		cell:wikitext(_ICON_SUBSTITUTE)
	end

	if mw.ext.TeamTemplate.teamexists(string.lower(args.team or '')) then
		cell:wikitext(mw.ext.TeamTemplate.teampart(args.team:lower()))
	end

	self.content:node(cell)
	return self
end

function SquadRow:name(args)
	local cell = mw.html.create('td')
	cell:addClass('Name')
	cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('('))
	cell:wikitext(args.name)
	cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext(')'))
	self.content:node(cell)
	return self
end

function SquadRow:role(args)
	local cell = mw.html.create('td')
	cell:addClass('Position')

	if not String.isEmpty(args.role) then
		cell:node(mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))
		cell:wikitext('\'\'(' .. args.role .. ')\'\'')
	end

	self.content:node(cell)
	return self
end

function SquadRow:date(dateValue, mobileTitle)
	local cell = mw.html.create('td')
	cell:addClass('Date')

	cell:node(mw.html.create('div'):addClass('MobileStuffDate'):wikitext(mobileTitle))

	if not String.isEmpty(dateValue) then
		cell:node(mw.html.create('div'):addClass('Date'):wikitext('\'\'' .. dateValue .. '\'\''))
	end
	self.content:node(cell)
	return self
end

function SquadRow:newteam(args)
	local cell = mw.html.create('td')
	cell:addClass('NewTeam')


	if not String.isEmpty(args.newteam) then
		local mobileStuffDiv = mw.html.create('div'):addClass('MobileStuff')
		mobileStuffDiv	:node(mw.html.create('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'))
						:wikitext('&nbsp;')
		cell:node(mobileStuffDiv)


		local newTeam = args.newteam:lower()
		if mw.ext.TeamTemplate.teamexists(newTeam) then
			cell:wikitext(mw.ext.TeamTemplate.team(args.newteam:lower(),
				args.newteamdate or ReferenceCleaner.clean(args.leavedate)))
		elseif self.options.useTemplatesForSpecialTeams then
			local newTeamTemplate = SquadRow.specialTeamsTemplateMapping[newTeam]
			if newTeamTemplate then
				cell:wikitext(Template.safeExpand(mw.getCurrentFrame(), newTeamTemplate))
			end
		end


		if not String.isEmpty(args.newteamrole) then
			cell:wikitext('&nbsp;\'\'<small>(' .. args.newteamrole .. ')</small>\'\'')
		end

	end

	self.content:node(cell)
	return self
end

function SquadRow:create()
	return self.content
end

return SquadRow
