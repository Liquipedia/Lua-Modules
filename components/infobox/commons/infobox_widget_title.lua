---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Infobox/Widget', {requireDevIfEnabled = true})

local Title = Class.new(
	Widget,
	function(self, input)
		self.content = self:assertExistsAndCopy(input.name)
	end
)

function Title:make()
	return {
		Title:_create(self.content)
	}
end

function Title:_create(infoDescription)
	local header = mw.html.create('div')
	header	:addClass('infobox-header')
			:addClass('wiki-backgroundcolor-light')
			:addClass('infobox-header-2')
			:wikitext(infoDescription)
	return mw.html.create('div'):node(header)
end

return Title

