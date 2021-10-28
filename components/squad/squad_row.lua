local Class = require('Module:Class')
local DivTable = require('Module:DivTable')
local Template = require('Module:Template')
local String = require('Module:String')

local _ICON_CAPTAIN = '[[image:Captain Icon.png|18px|baseline|Captain|link=https://liquipedia.net/rocketleague/Category:Captains|alt=Captain]]'
local _ICON_SUBSTITUTE = '[[image:Substitution.svg|18px|baseline|Sub|link=|alt=Substitution]]'

local SquadRow = Class.new(
	function(self, frame)
		self.frame = frame
		self.content = DivTable.Row()
	end)

function SquadRow:id(args)
	local cell = mw.html.create('div')
	cell:addClass('ID')
	cell:wikitext('\'\'\'' ..
		Template.safeExpand(self.frame, 'Player', {args.player, flag = args.flag, link = args.link}) .. '\'\'\'')

	if not String.isEmpty(args.captain) then
		cell:wikitext(_ICON_CAPTAIN)
	end

	if args.role == 'sub' then
		cell:wikitext(_ICON_SUBSTITUTE)
	end

	self.content:cell(cell)
	return self
end

function SquadRow:name(args)
	local cell = mw.html.create('div')
	cell:addClass('Name')
	cell:wikitext(args.name)
	self.content:cell(cell)
	return self
end

function SquadRow:role(args)
	local cell = mw.html.create('div')
	cell:addClass('Position')
	cell:wikitext(args.role)
	self.content:cell(cell)
	return self
end

function SquadRow:joinDate(args)
	local cell = mw.html.create('div')
	cell:addClass('Date')
	cell:wikitext(args.joindate)
	self.content:cell(cell)
	return self
end

function SquadRow:create()
	return self.content
end

return SquadRow
