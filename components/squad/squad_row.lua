---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:String')
local Player = require('Module:Player')
local ReferenceCleaner = require('Module:ReferenceCleaner')
local Template = require('Module:Template')
local Flags = require('Module:Flags')

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

		self.lpdbData = {}
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
	cell:wikitext('\'\'\'' .. Player._player(args) .. '\'\'\'')

	if not String.isEmpty(args.captain) then
		cell:wikitext('&nbsp;' .. _ICON_CAPTAIN)
	end

	if args.role == 'sub' then
		cell:wikitext('&nbsp;' .. _ICON_SUBSTITUTE)
	end

	if mw.ext.TeamTemplate.teamexists(string.lower(args.team or '')) then
		cell:wikitext(mw.ext.TeamTemplate.teampart(args.team:lower()))
	end

	self.content:node(cell)

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

	if not String.isEmpty(args.role) then
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

	if not String.isEmpty(dateValue) then
		cell:node(mw.html.create('div'):addClass('Date'):wikitext('\'\'' .. dateValue .. '\'\''))
	end
	self.content:node(cell)

	self.lpdbData[lpdbColumn] = ReferenceCleaner.clean(dateValue)

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


		if not String.isEmpty(args.newteamrole) then
			cell:wikitext('&nbsp;\'\'<small>(' .. args.newteamrole .. ')</small>\'\'')
		end

	end

	self.content:node(cell)

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
