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
local Table = require('Module:Table')

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
	-- todo: make it xpcall and do the traceback in there
	local result, output = pcall(self.make, self) -- Equivalent of self:make()
	if not result then
		-- log stacked trace call and log self
		mw.log('-----Error in Widget:tryMake()-----')
		mw.logObject(output, 'error')
		mw.logObject(self, 'widget')
		mw.log(debug.traceback())
		output = {String.interpolate(_ERROR_TEXT, {errorMessage = output})}
		output = {ErrorWidget({content = output})}
	end

	return output
end

function Widget:setContext(context)
	self.context = context
	if context.injector ~= nil and
		(context.injector['is_a'] == nil or context.injector:is_a(Injector) == false) then
		return error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
end

-- error widget for displaying errors of child widgets
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
	if Table.isEmpty(content) then
		return nil
	end

	local errorDiv = mw.html.create('div'):addClass('infobox-center')

	for _, item in pairs(content) do
		errorDiv:wikitext(item)
	end

	return mw.html.create('div'):node(errorDiv)
end

return Widget
