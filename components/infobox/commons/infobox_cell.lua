---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Cell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Variables = require('Module:Variables')

local Cell = Class.new()

function Cell:new(description)
	self.root = mw.html.create('div')
	self.description = mw.html.create('div')
	self.description:addClass('infobox-cell-2')
					:addClass('infobox-description')
					:wikitext(description .. ':')
	self.contentDiv = nil
	self.args = nil
	self.setCategories = nil
	return self
end

function Cell:addClass(class)
	self.root:addClass(class)
	return self
end

function Cell:options(args)
	self.args = args
	return self
end

function Cell:content(...)
	self.contentText = ...
	local firstItem = select(1, ...)
	if firstItem == nil or firstItem == '' then
		self.contentDiv = nil
		return self
	end

	self.contentDiv = mw.html.create('div')
	self.contentDiv:addClass('infobox-cell-2')
	for i = 1, select('#', ...) do
		if i > 1 then
			self.contentDiv:wikitext('<br/>')
		end
		local item = select(i, ...)
		if item == nil then
			break
		end

		if self.args ~= nil and self.args.makeLink == true then
			self.contentDiv:wikitext('[[' .. item .. ']]')
		else
			self.contentDiv:wikitext(item)
		end
	end
	return self
end

--- Allows categories to be set based on a certain cell value
---@param setCategories function callback function that allows setting of categories
---@return table Cell
function Cell:categories(setCategories)
	self.setCategories = setCategories
	return self
end

function Cell:variables(...)
	for i = 1, select('#', ...) do
		local item = select(i, ...)
		Variables.varDefine(item.key, item.value)
	end
	return self
end

function Cell:make()
	if self.contentDiv == nil then
		return ''
	end

	if self.setCategories ~= nil then
		self.setCategories(self, self.contentText)
	end

	self.root	:node(self.description)
				:node(self.contentDiv)
	return self.root
end

return Cell
