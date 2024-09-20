---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Fragment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')

---@class FragmentWidget: Widget
---@operator call(WidgetParameters): FragmentWidget
local Fragment = Class.new(Widget)

---@param children string[]
---@return string?
function Fragment:make(children)
	local div = mw.html.create()
	Array.forEach(children, FnUtil.curry(div.node, div))
	return tostring(div)
end

return Fragment
