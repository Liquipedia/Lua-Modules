---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

---@class Widget: BaseClass
---@operator call(): Widget
---@field public injector WidgetInjector?
local Widget = Class.new()

local _ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'

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
			return {Widget.Error({errorMessage = errorMessage})}
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
