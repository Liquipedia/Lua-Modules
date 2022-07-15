---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Arguments = require('Module:Arguments')
local String = require('Module:StringUtils')

local Squad = Class.new()

Squad.TYPE_ACTIVE = 0
Squad.TYPE_INACTIVE = 1
Squad.TYPE_FORMER = 2
Squad.TYPE_FORMER_INACTIVE = 3

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
		self.args.isLoan = true
	end

	local status = (self.args.status or 'active'):lower()

	if status == 'inactive' then
		self.type = Squad.TYPE_INACTIVE
	elseif status == 'former' then
		self.type = Squad.TYPE_FORMER
	else
		self.type = Squad.TYPE_ACTIVE
	end

	return self
end

function Squad:title()
	local defaultTitle
	if self.type == Squad.TYPE_FORMER then
		defaultTitle = 'Former Squad'
	elseif self.type == Squad.TYPE_INACTIVE then
		defaultTitle = 'Inactive Squad'
	else
		defaultTitle = 'Active Squad'
	end

	local titleText = String.isEmpty(self.args.title) and defaultTitle or self.args.title

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

function Squad:header()
	local makeHeader = function(wikiText)
		local headerCell = mw.html.create('th')

		if wikiText == nil then
			return headerCell
		end

		return headerCell:wikitext(wikiText):addClass('divCell')
	end

	local headerRow = mw.html.create('tr'):addClass('HeaderRow')

		headerRow	:node(makeHeader('ID'))
					:node(makeHeader()) -- "Team Icon" (most commmonly used for loans)
					:node(makeHeader('Name'))
					:node(makeHeader()) -- "Role"
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

function Squad:row(row)
	self.content:node(row)
	return self
end

function Squad:create()
	self.root:node(self.content)

	return self.root
end

return Squad
