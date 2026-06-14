---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {children: Renderable|Renderable[]?}
---@return VNode?
local function MatchSummaryFooter(props)
	local children = props.children
	if Logic.isEmpty(children) then
		return
	end
	return Div{
		classes = {'brkts-popup-footer'},
		children = Div{
			classes = {'brkts-popup-spaced', 'vodlink'},
			children = children
		}
	}
end

return Component.component(MatchSummaryFooter)
