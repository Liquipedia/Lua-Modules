---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenSort
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local HiddenSort = {}

function HiddenSort.run(sortText)
	return mw.html.create('span')
		:css('display', 'none')
		:wikitext(sortText)
end

return Class.export(HiddenSort)
