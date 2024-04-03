---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')

---@class Widget: BaseClass
---@operator call(): Widget
---@field public injector WidgetInjector?
local Widget = Class.new()

---Asserts the existence of a value and copies it
---@param value string
---@return string
function Widget:assertExistsAndCopy(value)
	if value == nil or value == '' then
		error('Tried to set a nil value to a mandatory property')
	end

	return value
end

---@return Widget[]|Html[]|nil
function Widget:make()
	error('A Widget must override the make() function!')
end

---@return Widget[]|Html[]|nil
function Widget:tryMake()
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

---Sets the context of a widget
---@param context table
function Widget:setContext(context)
	self.context = context
	if context.injector ~= nil and (context.injector['is_a'] == nil or context.injector:is_a(Injector) == false) then
		error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
end

return Widget
