---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {flip: boolean?, children: Renderable[]}
---@return VNode
local function InlinePlayerWrapper(props)
	return Html.Span{
		classes = {
			'inline-player',
			props.flip and 'flipped' or nil,
		},
		css = {['white-space'] = 'pre'},
		children = Array.interleave(
			props.flip and Array.reverse(props.children) or props.children,
			'&nbsp;'
		)
	}
end

return Component.component(InlinePlayerWrapper)
