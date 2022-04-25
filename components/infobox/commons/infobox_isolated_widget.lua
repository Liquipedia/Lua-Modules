---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/IsolatedWidget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Widget = require('Module:Infobox/Widget')

local IsolatedWidget = Class.new(Widget)

local _ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'

function IsolatedWidget:make()
	local result, output = pcall(self.create, self) -- Equivalent of self:create()
	if not result then
		output = {String.interpolate(_ERROR_TEXT, {errorMessage = output})}
	end
	return output
end

function IsolatedWidget:create()
	return error('An IsolatedWidget must override the create() function!')
end

return IsolatedWidget
