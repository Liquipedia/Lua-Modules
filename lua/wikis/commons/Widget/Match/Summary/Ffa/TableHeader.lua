---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {children?: Renderable|Renderable[]}
---@return HtmlNode
function MatchSummaryFfaTableHeader(props)
	return Html.Div{
		classes = {'panel-table__row', 'row--header'},
		attributes = {
			['data-js-battle-royale'] = 'header-row'
		},
		children = props.children
	}
end

return Component.component(MatchSummaryFfaTableHeader)
