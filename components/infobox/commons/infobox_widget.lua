---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local String = require('Module:StringUtils')

local Widget = Class.new()
local ErrorWidget

local _ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'

function Widget:assertExistsAndCopy(value)
	if value == nil or value == '' then
		return error('Tried to set a nil value to a mandatory property')
	end

	return value
end

function Widget:make()
	return error('A Widget must override the make() function!')
end

function Widget:tryMake()
	local result, erroOutput
	xpcall(
		function()
			result = self:make()
		end,
		function(message)
			mw.log('-----Error in Widget:tryMake()-----')
			mw.logObject(message, 'error')
			mw.logObject(self, 'widget')
			mw.log(debug.traceback())
			erroOutput = String.interpolate(_ERROR_TEXT, {errorMessage = message})
			erroOutput = {ErrorWidget({content = erroOutput})}
		end
	)

	-- if no error occurs then `erroOutput` is nil, so the result is taken
	return erroOutput or result
end

function Widget:setContext(context)
	self.context = context
	if context.injector ~= nil and
		(context.injector['is_a'] == nil or context.injector:is_a(Injector) == false) then
		return error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
end

-- error widget for displaying errors of widgets
-- have to add it here instead of a sep. module to avoid circular requires
ErrorWidget = Class.new(
	Widget,
	function(self, input)
		self.content = input.content
	end
)

function ErrorWidget:make()
	return {
		ErrorWidget:_create(self.content)
	}
end

function ErrorWidget:_create(content)
	local errorDiv = mw.html.create('div')
		:node(content)

	return mw.html.create('div'):node(errorDiv)
end

return Widget
