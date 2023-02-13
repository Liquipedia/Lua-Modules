---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Infobox/Widget', {requireDevIfEnabled = true})

local Cell = Class.new(Widget,
	function(self, input)
		self.name = self:assertExistsAndCopy(input.name)
		self.content = input.content
		self.options = input.options or {}
		self.classes = input.classes

		self.options.columns = self.options.columns or 2
	end
)

function Cell:_new(description)
	self.root = mw.html.create('div')
	self.description = mw.html.create('div')
	self.description:addClass('infobox-cell-'.. self.options.columns)
					:addClass('infobox-description')
					:wikitext(description .. ':')
	self.contentDiv = nil
	return self
end

function Cell:_class(...)
	for i = 1, select('#', ...) do
		local item = select(i, ...)
		if item == nil then
			break
		end

		self.root:addClass(item)
	end
	return self
end

function Cell:_content(...)
	local firstItem = select(1, ...)
	if firstItem == nil or firstItem == '' then
		self.contentDiv = nil
		return self
	end

	self.contentDiv = mw.html.create('div')
	self.contentDiv:css('width', (100 * (self.options.columns - 1) / self.options.columns) .. '%') -- 66.66% for col = 3
	for i = 1, select('#', ...) do
		if i > 1 then
			self.contentDiv:wikitext('<br/>')
		end
		local item = select(i, ...)
		if item == nil then
			break
		end

		if self.options.makeLink == true then
			self.contentDiv:wikitext('[[' .. item .. ']]')
		else
			self.contentDiv:wikitext(item)
		end
	end
	return self
end

function Cell:make()
	self:_new(self.name)
	self:_class(unpack(self.classes or {}))
	self:_content(unpack(self.content))

	if self.contentDiv == nil then
		return {}
	end

	self.root	:node(self.description)
				:node(self.contentDiv)
	return {
		self.root
	}
end

return Cell
