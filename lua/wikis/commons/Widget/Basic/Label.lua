---
-- @Liquipedia
-- page=Module:Widget/Basic/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class GenericLabelProps: HtmlNodeProps
---@field labelScheme string?
---@field labelScale number?
---@field labelType string?

---@param props GenericLabelProps
---@return HtmlNode
local function GenericLabel(props)
	if props.labelScale then
		props.css = props.css or {}
		props.css['--label-scale'] = props.labelScale
	end
	if props.labelType then
		props.attributes = props.attributes or {}
		props.attributes['data-label-type'] = props.labelType
	end

	return Html.Div{
		attributes = props.attributes,
		classes = {
			'generic-label',
			props.labelScheme and ('label--' .. props.labelScheme) or nil,
		},
		css = props.css,
		children = props.children,
	}
end

return Component.component(GenericLabel)
