---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameTeamWrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

local defaultProps = {
	flipped = false,
}

---@param props {flipped: boolean?, children: Renderable|Renderable[]}
---@return VNode?
local function MatchSummaryMatchGameTeamWrapper(props)
	return Html.Div{
		classes = {'brkts-popup-spaced'},
		css = {flex = 1, ['justify-content'] = 'unset', ['flex-direction'] = props.flipped and 'row-reverse' or 'row'},
		children = props.children
	}
end

return Component.component(MatchSummaryMatchGameTeamWrapper, defaultProps)
