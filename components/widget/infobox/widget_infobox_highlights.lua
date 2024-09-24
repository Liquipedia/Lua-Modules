---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Highlights
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')

---@class HighlightsWidget: Widget
---@operator call({content: (string|number)[]?}):HighlightsWidget
local Highlights = Class.new(
	Widget,
	function(self, input)
		self.children = input.children or input.content or {}
	end
)

---@param children string[]
---@return string?
function Highlights:make(children)
	return Highlights:_highlights(children)
end

---@param list (string|number)[]?
---@return string?
function Highlights:_highlights(list)
	if list == nil or Table.size(list) == 0 then
		return nil
	end

	local div = mw.html.create('div')
	local highlights = mw.html.create('ul')

	for _, item in ipairs(list) do
		highlights:tag('li'):wikitext(item):done()
	end

	div:node(highlights)

	return tostring(div)
end

return Highlights
