---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local DisplayUtil = require('Module:DisplayUtil')
local ErrorDisplay = require('Module:Error/Display')
local FnUtil = require('Module:FnUtil')
local String = require('Module:StringUtils')

---@class Widget: BaseClass
---@operator call(): Widget
local Widget = Class.new()

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	return assert(String.nilIfEmpty(value), 'Tried to set a nil value to a mandatory property')
end

---@param props {injector: WidgetInjector?}
---@return Widget[]|Html[]|nil
function Widget:make(props)
	error('A Widget must override the make() function!')
end

---@param injector WidgetInjector?
---@return Widget[]|Html[]|nil
function Widget:tryMake(injector)
	return DisplayUtil.TryPureComponent(FnUtil.Curry(self.make, self), {injector}, ErrorDisplay.InlineError)
end

return Widget
