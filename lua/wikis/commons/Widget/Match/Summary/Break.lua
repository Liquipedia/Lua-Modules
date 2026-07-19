---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Break
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props table?
---@return VNode
local function MatchSummaryBreak(props)
	return Div{
		classes = {'brkts-popup-break'},
	}
end

return Component.component(MatchSummaryBreak)
