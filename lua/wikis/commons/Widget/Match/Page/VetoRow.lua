---
-- @Liquipedia
-- page=Module:Widget/Match/Page/VetoRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class MatchPageVetoRowParameters
---@field vetoType 'pick'|'ban'
---@field side string?
---@field vetoItems VNode<MatchPageVetoItemProps>[]

---@param props MatchPageVetoRowParameters
---@return VNode
local function MatchPageVetoRow(props)
	local vetoType = props.vetoType
	return Div{
		classes = {
			'match-bm-game-veto-overview-team-veto-row',
			'match-bm-game-veto-overview-team-veto-row--' .. (
				vetoType == 'pick' and props.side or vetoType
			)
		},
		attributes = {['aria-labelledby'] = vetoType .. 's'},
		children = props.vetoItems
	}
end

return Component.component(MatchPageVetoRow)
