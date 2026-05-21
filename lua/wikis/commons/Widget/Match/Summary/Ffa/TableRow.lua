---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/TableRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children?: Renderable|Renderable[]}
---@return HtmlNode
local function MatchSummaryFfaTableRow(props)
	return Html.Div{
		classes = {'panel-table__row'},
		attributes = {
			['data-js-battle-royale'] = 'row'
		},
		children = props.children
	}
end

return Component.component(MatchSummaryFfaTableRow)
