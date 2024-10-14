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
---@operator call(table): TitleWidget
local Title = Class.new(
	Widget,
	function(self)
		-- Legacy support for single string children, convert to array
		-- Widget v2.1 will have this support added to the base class
		if type(self.children) == 'string' then
			self.children = {self.children}
		end
	end
)

---@param children string[]
---@return string?
function Title:make(children)
	return Title:_create(table.concat(children))
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
