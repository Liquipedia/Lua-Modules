---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Title
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Widget = require('Module:Infobox/Widget')

local Title = Class.new(
	Widget,
	function(self, input)
		self.content = self:assertExistsAndCopy(input.name)
		self.level = input.level
	end
)

function Title:make()
	return {
		Title:_create(self.content, self.level)
	}
end

function Title:_create(infoDescription. level)
	level = tonumber(level or 2)
	--only allow "3" as manual entry for the level
	if level ~= 3 then
		level = 2
	end

	local header = mw.html.create('div')
	header	:addClass('infobox-header')
			:addClass('wiki-backgroundcolor-light')
			:addClass('infobox-header-' .. level)
			:wikitext(infoDescription)
	return mw.html.create('div'):node(header)
end

return Title

