---
-- @Liquipedia
-- page=Module:Widget/Basic/Box
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class BoxProps
---@field children Renderable[]|Renderable
---@field maxWidth string?
---@field paddingLeft string?
---@field paddingBottom string?
---@field paddingRight string?
---@field width string?
---@field height string?

---@param props BoxProps
---@return Renderable
local function Box(props)
	local children = props.children
	if not Array.isArray(children) then
		return props.children
	end
	---@cast children Renderable[]

	return Html.Div{
		css = {['max-width'] = props.maxWidth},
		children = Array.map(children, function(child)
			return Html.Div{
				classes = {'template-box'},
				css = {
					['padding-left'] = props.paddingLeft,
					['padding-bottom'] = props.paddingBottom,
					['padding-right'] = props.paddingRight,
					width = props.width,
					height = props.height,
					overflow = props.height and 'hidden' or nil,
				},
				children = child,
			}
		end)
	}
end

return Component.component(Box)
