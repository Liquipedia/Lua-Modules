---
-- @Liquipedia
-- page=Module:Widget/Documentation/Para
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class DocumentationParaProps
---@field name string? # Nil for an unnamed parameter
---@field value (string|number|boolean)? # Shown as written, not rendered

---The widget equivalent of Template:Para, e.g. `|name=value`.
---@param props DocumentationParaProps
---@return HtmlNode
local function DocumentationPara(props)
	local value = props.value ~= nil and mw.text.nowiki(tostring(props.value)) or nil
	return Html.Code{
		classes = {'nowrap'},
		children = props.name and {'&#124;', props.name, '&#61;', value} or {'&#124;', value},
	}
end

return Component.component(DocumentationPara)
