---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local String = require('Module:StringUtils')

---@class Widget: BaseClass
---@operator call(): Widget
local Widget = Class.new()

local _ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'

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
			return {Widget.Error({errorMessage = errorMessage})}
		end
	)

	return output
end

-- error widget for displaying errors of widgets
-- have to add it here instead of a sep. module to avoid circular requires
local ErrorWidget = Class.new(
	Widget,
	function(self, input)
		self.errorMessage = input.errorMessage
	end
)

function ErrorWidget:make()
	return {
		ErrorWidget:_create(self.errorMessage)
	}
end

function ErrorWidget:_create(errorMessage)
	local errorOutput = String.interpolate(_ERROR_TEXT, {errorMessage = errorMessage})
	local errorDiv = mw.html.create('div'):node(errorOutput)

	return mw.html.create('div'):node(errorDiv)
end

Widget.Error = ErrorWidget

return Widget
