local Class = require('Module:Class')
local String = require('Module:String')
local Player = require('Module:Player')

local _ICON_CAPTAIN = '[[image:Captain Icon.png|18px|baseline|Captain|link=' ..
	'https://liquipedia.net/rocketleague/Category:Captains|alt=Captain]]'
local _ICON_SUBSTITUTE = '[[image:Substitution.svg|18px|baseline|Sub|link=|alt=Substitution]]'

local SquadRow = Class.new(
	function(self, frame)
		self.frame = frame
		self.content = mw.html.create('tr'):addClass('Player')
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
	cell:wikitext(args.role)
	self.content:node(cell)
	return self
end

function SquadRow:joinDate(args)
	local cell = mw.html.create('td')
	cell:addClass('Date')
	cell:wikitext(args.joindate)
	self.content:node(cell)
	return self
end

function SquadRow:create()
	return self.content
end

return SquadRow
