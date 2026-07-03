---
-- @Liquipedia
-- page=Module:HiddenSort
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Html = Lua.import('Module:Widget/Html')

local HiddenSort = {}

---Creates a hiddensort span
---@param sortText string|number?
---@return VNode
function HiddenSort.run(sortText)
	return Html.Span{
		css = {display = 'none'},
		children = sortText
	}
end

return HiddenSort
