---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class TitleWidget: Widget
---@operator call({name: string|number|nil}): TitleWidget
local Title = Class.new(
	Widget,
	function(self, input)
		self.children = {self:assertExistsAndCopy(input.children or input.name)}
	end
)

---@param children string[]
---@return string?
function Title:make(children)
	return Title:_create(children[1])
end

---@param infoDescription string|number|nil
---@return string
function Title:_create(infoDescription)
	local header = mw.html.create('div')
	header	:addClass('infobox-header')
			:addClass('wiki-backgroundcolor-light')
			:addClass('infobox-header-2')
			:wikitext(infoDescription)
	return tostring(mw.html.create('div'):node(header))
end

return Title

