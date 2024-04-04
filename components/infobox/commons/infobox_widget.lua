---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Lua = require('Module:Lua')

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
	local _, output = xpcall(
		function()
			return self:make()
		end,
		function(errorMessage)
			mw.log('-----Error in Widget:tryMake()-----')
			mw.logObject(errorMessage, 'error')
			mw.logObject(self, 'widget')
			mw.log(debug.traceback())
			local ErrorWidget = Lua.import('Module:Infobox/Widget/Error')
			return {ErrorWidget({errorMessage = errorMessage})}
		end
	)

	return output
end

return Widget
