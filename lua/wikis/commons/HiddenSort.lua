---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenSort
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local HiddenSort = {}

---Creates a hiddensort span
---@param sortText string|number|nil
---@return Html
function HiddenSort.run(sortText)
	return mw.html.create('span')
		:css('display', 'none')
		:wikitext(sortText)
end

return HiddenSort
