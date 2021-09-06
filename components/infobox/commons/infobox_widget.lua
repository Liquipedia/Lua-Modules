---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')

local Widget = Class.new()

function Widget:assertExistsAndCopy(value)
	if value == nil or value == '' then
		return error('Tried to set a nil value to a mandatory property')
	end

	return value
end

function Widget:make()
	return error('A Widget must override the make() function!')
end

function Widget:setContext(context)
	self.context = context
	if context.injector ~= nil and
		(context.injector['is_a'] == nil or context.injector:is_a(Injector) == false) then
		return error('Valid Injector from Infobox/Widget/Injector needs to be provided')
	end
end

return Widget
