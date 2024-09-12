---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Builder
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetFactory = Lua.import('Module:Widget/Factory')

---@class BuilderWidget: Widget
---@operator call({builder: function}): BuilderWidget
---@field builder fun(): Widget[]
local Builder = Class.new(
	Widget,
	function(self, input)
		self.builder = input.builder
	end
)

---@param injector WidgetInjector?
---@return string
function Builder:make(injector)
	local children = self.builder()
	local builtChildren = mw.html.create()
	for _, child in ipairs(children or {}) do
		builtChildren:node(WidgetFactory.work(child, injector))
	end
	return tostring(builtChildren)
end

return Builder
