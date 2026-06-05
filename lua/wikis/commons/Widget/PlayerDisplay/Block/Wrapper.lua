---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Block/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html/All')

---@param props {flip: boolean?, showPlayerTeam: boolean?, classes: string[]?, children: Renderable[]}
---@return VNode
local function BlockPlayerWrapper(props)
	return Html.Div{
		classes = Array.extend(
			'block-player',
			props.flip and 'flipped' or nil,
			props.showPlayerTeam and 'has-team' or nil,
			props.classes
		),
		css = {['white-space'] = 'pre'},
		children = props.children
	}
end

return Component.component(BlockPlayerWrapper)
