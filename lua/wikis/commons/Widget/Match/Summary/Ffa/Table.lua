---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children?: Renderable|Renderable[]}
---@return VNode
local function MatchSummaryFfaTable(props)
	return Html.Div{
		classes = {'panel-table'},
		attributes = {
			['data-js-battle-royale'] = 'table',
		},
		children = props.children,
	}
end

return Component.component(MatchSummaryFfaTable)
