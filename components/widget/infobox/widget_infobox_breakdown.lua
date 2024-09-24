---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Breakdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class BreakdownWidget: Widget
---@operator call({children:(string|number)[],classes:string[],contentClasses:table<integer,string[]>}):BreakdownWidget
---@field classes string[]
---@field contentClasses table<integer, string[]> --can have gaps in the outer table
local Breakdown = Class.new(
	Widget,
	function(self, input)
		self.classes = input.classes
		self.contentClasses = input.contentClasses or {}
	end
)

---@param children string[]
---@return string?
function Breakdown:make(children)
	return Breakdown:_breakdown(children, self.classes, self.contentClasses)
end

---@param contents (string|number)[]
---@param classes string[]
---@param contentClasses table<integer, string[]> --can have gaps in the outer table
---@return string?
function Breakdown:_breakdown(contents, classes, contentClasses)
	if type(contents) ~= 'table' or contents == {} then
		return nil
	end

	local div = mw.html.create('div')
	local number = #contents
	for contentIndex, content in ipairs(contents) do
		local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number)
		for _, class in pairs(classes or {}) do
			infoboxCustomCell:addClass(class)
		end
		for _, class in pairs(contentClasses['content' .. contentIndex] or {}) do
			infoboxCustomCell:addClass(class)
		end
		infoboxCustomCell:wikitext(content)
		div:node(infoboxCustomCell)
	end

	return tostring(div)
end

return Breakdown
