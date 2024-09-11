---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class ChronologyWidget: Widget
---@operator call({content: table<string, string|number|nil>}): ChronologyWidget
---@field links table<string, string|number|nil>
local Chronology = Class.new(
	Widget,
	function(self, input)
		self.links = input.content
	end
)

---@param injector WidgetInjector?
---@return Html[]
function Chronology:make(injector)
	return Chronology:_chronology(self.links)
end

---@param links table<string, string|number|nil>
---@return Html[]
function Chronology:_chronology(links)
	if links == nil or Table.size(links) == 0 then
		return self
	end

	local chronologyContent = {}
	chronologyContent[1] = self:_createChronologyRow(links['previous'], links['next'])

	local index = 2
	local previous = links['previous' .. index]
	local next = links['next' .. index]
	while (previous ~= nil or next ~= nil) do
		chronologyContent[index] = self:_createChronologyRow(previous, next)

		index = index + 1
		previous = links['previous' .. index]
		next = links['next' .. index]
	end

	return chronologyContent
end

---@param previous string|number|nil
---@param next string|number|nil
---@return Html?
function Chronology:_createChronologyRow(previous, next)
	local doesPreviousExist = previous ~= nil and previous ~= ''
	local doesNextExist = next ~= nil and next ~= ''

	if not doesPreviousExist and not doesNextExist then
		return nil
	end

	local node = mw.html.create('div')

	local previousWrapper = mw.html.create('div'):addClass('infobox-cell-2')
	if doesPreviousExist then
		previousWrapper :addClass('infobox-text-left')

		local previousArrow = mw.html.create('div')
		previousArrow	:addClass('infobox-arrow-icon')
						:css('float', 'left')
						:wikitext('[[File:Arrow sans left.svg|link=' .. previous .. ']]')

		previousWrapper	:node(previousArrow)
						:wikitext('&nbsp;[[' .. previous .. ']]')
	end
	node:node(previousWrapper)

	if doesNextExist then
		local nextWrapper = mw.html.create('div')
		nextWrapper	:addClass('infobox-cell-2')
					:addClass('infobox-text-right')

		local nextArrow = mw.html.create('div')
		nextArrow	:addClass('infobox-arrow-icon')
					:css('float', 'right')
					:wikitext('[[File:Arrow sans right.svg|link=' .. next .. ']]')

		nextWrapper	:wikitext('[[' .. next .. ']]&nbsp;')
					:node(nextArrow)

		node:node(nextWrapper)
	end

	return node
end

return Chronology

