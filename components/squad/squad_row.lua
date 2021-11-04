local Class = require('Module:Class')
local String = require('Module:String')
local Player = require('Module:Player')

local _ICON_CAPTAIN = '[[image:Captain Icon.png|18px|baseline|Captain|link=' ..
	'https://liquipedia.net/rocketleague/Category:Captains|alt=Captain]]'
local _ICON_SUBSTITUTE = '[[image:Substitution.svg|18px|baseline|Sub|link=|alt=Substitution]]'

local SquadRow = Class.new(
	function(self, frame, role)
		self.frame = frame
		self.content = mw.html.create('tr'):addClass('Player')

		role = string.lower(role or '')

		if role == 'sub' then
			self.content:addClass('sub')
		elseif role == 'coach' then
			self.content:addClass('coach')
			self.content:css('background-color', '#e5e5e5')
		elseif role == 'coach/manager' then
			self.content:addClass('coach/manager')
			self.content:css('background-color', '#e5e5e5')
		elseif role == 'coach/substitute' then
			self.content:addClass('coach/substitute')
			self.content:css('background-color', '#e5e5e5')
		end
	end)

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

	self.content:node(cell)
	return self
end

function SquadRow:name(args)
	local cell = mw.html.create('td')
	cell:addClass('Name')
	cell:wikitext(args.name)
	self.content:node(cell)
	return self
end

function SquadRow:role(args)
	local cell = mw.html.create('td')
	cell:addClass('Position')

	if not String.isEmpty(args.role) then
		cell:wikitext('\'\'(' .. args.role .. ')\'\'')
	end

	self.content:node(cell)
	return self
end

function SquadRow:date(dateValue)
	local cell = mw.html.create('td')
	cell:addClass('Date')

	if not String.isEmpty(dateValue) then
		cell:wikitext('\'\'' .. dateValue .. '\'\'')
	end
	self.content:node(cell)
	return self
end

function SquadRow:newteam(args)
	local cell = mw.html.create('td')
	cell:addClass('NewTeam')

	if not String.isEmpty(dateValue) then
		cell:wikitext('\'\'' .. dateValue .. '\'\'')
	end
	self.content:node(cell)
	return self

end

function SquadRow:create()
	return self.content
end

return SquadRow
