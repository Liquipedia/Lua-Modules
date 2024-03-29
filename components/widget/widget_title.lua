---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class TitleWidget: Widget
---@operator call({name: string|number|nil}): TitleWidget
---@field content string|number|nil
local Title = Class.new(
	Widget,
	function(self, input)
		self.content = self:assertExistsAndCopy(input.name)
	end
)

---@param injector WidgetInjector?
---@return {[1]: Html}
function Title:make(injector)
	return {Title:_create(self.content)}
end

---@param infoDescription string|number|nil
---@return Html
function Title:_create(infoDescription)
	local header = mw.html.create('div')
	header	:addClass('infobox-header')
			:addClass('wiki-backgroundcolor-light')
			:addClass('infobox-header-2')
			:wikitext(infoDescription)
	return mw.html.create('div'):node(header)
end

return Title

