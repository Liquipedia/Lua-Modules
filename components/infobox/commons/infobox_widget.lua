---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local ErrorDisplay = require('Module:Error/Display')
local Logic = require('Module:Logic')
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

---@param injector WidgetInjector?
---@return Widget[]|Html[]|nil
function Widget:make(injector)
	error('A Widget must override the make() function!')
end

---@param injector WidgetInjector?
---@return Widget[]|Html[]|nil
function Widget:tryMake(injector)
	local f = function() return self:make(injector) end
	local e = function (error) return {ErrorDisplay.InlineError(error)} end
	return Logic.tryOrElseLog(f, e)
end

return Widget
