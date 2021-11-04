local Class = require('Module:Class')
local Arguments = require('Module:Arguments')
local String = require('Module:String')
local Variables = require('Module:Variables')
local Logic = require('Module:Logic')

local Squad = Class.new()

Squad.TYPE_ACTIVE = 0
Squad.TYPE_FORMER = 1

function Squad:init(frame)
	self.frame = frame
	self.args = Arguments.getArgs(frame)
	self.root = mw.html.create('div')
	self.root	:addClass('table-responsive')
				-- TODO: is this needed?
				:css('margin-bottom', '10px')
				-- TODO: is this needed?
				:css('padding-bottom', '0px')

	self.content = mw.html.create('table')
	self.content:addClass('wikitable wikitable-striped roster-card')

	if not String.isEmpty(self.args.team) then
		-- TODO find out what it is
		Variables.varDefine('RosterTeam', 'true')
	end

	return self
end

function Squad:title()
	local titleText = String.isEmpty(self.args.title) and 'Active Squad' or self.args.title

	local titleContainer = mw.html.create('tr')

	local titleRow = mw.html.create('th')
	titleRow:addClass('large-only')
			:attr('colspan', '1')
			:wikitext(titleText)

	local titleRow2 = mw.html.create('th')
	titleRow2:addClass('large-only')
			:attr('colspan', '10')
			:css('border-bottom', '1px solid #bbbbbb')
			:wikitext(titleText)

	titleContainer:node(titleRow):node(titleRow2)
	self.content:node(titleContainer)

	return self
end

function Squad:header(type)
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
					:node(makeHeader('Join Date'))
	if type == Squad.TYPE_FORMER then
		Variables.varDefine('RosterFormer', 'true')
		headerRow	:node(makeHeader('Leave Date'))
					:node(makeHeader('New Team'))
	end
	self.content:node(headerRow)

	return self
end

function Squad:row(row)
	self.content:node(row)
	return self
end

function Squad:create()
	self.root:node(self.content)

	if not (String.isEmpty(self.args.former) and String.isEmpty(self.args.inactive)) then
		if Logic.readBool(self.args.inactive) == true then
			Variables.varDefine('RosterInactive', 'true')
		end

		Variables.varDefine('number_in_roster', 0)
	end

	return self.root
end

return Squad
