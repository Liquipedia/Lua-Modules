---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Error
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Widget = Lua.import('Module:Infobox/Widget')

local ERROR_TEXT = '<span style="color:#ff0000;font-weight:bold" class="show-when-logged-in">' ..
					'Unexpected Error, report this in #bugs on our [https://discord.gg/liquipedia Discord]. ' ..
					'${errorMessage}' ..
					'</span>[[Category:Pages with script errors]]'


-- For displaying errors
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
	local errorOutput = String.interpolate(ERROR_TEXT, {errorMessage = errorMessage})
	local errorDiv = mw.html.create('div'):node(errorOutput)

	return mw.html.create('div'):node(errorDiv)
end

return ErrorWidget
