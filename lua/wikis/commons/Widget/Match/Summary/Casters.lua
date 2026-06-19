---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Casters
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {casters: {name: string?, displayName: string?, flag: string?}[]}
---@return VNode?
local function MatchSummaryCasters(props)
	if type(props.casters) ~= 'table' then
		return
	end

	local casters = DisplayHelper.createCastersDisplay(props.casters)

	if #casters == 0 then
		return
	end

	return Html.Div{
		classes = {'brkts-popup-comment'},
		children = WidgetUtil.collect(
			Html.B{children = {#casters > 1 and 'Casters: ' or 'Caster: '}},
			Array.interleave(casters, ', ')
		),
	}
end

return Component.component(MatchSummaryCasters)
