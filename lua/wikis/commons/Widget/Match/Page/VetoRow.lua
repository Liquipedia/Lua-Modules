---
-- @Liquipedia
-- page=Module:Widget/Match/Page/VetoRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageVetoRowParameters
---@field vetoType 'pick'|'ban'
---@field side string?
---@field vetoItems MatchPageVetoItem[]

---@class MatchPageVetoRow: Widget
---@operator call(MatchPageVetoRowParameters): MatchPageVetoRow
---@field props MatchPageVetoRowParameters
local MatchPageVetoRow = Class.new(Widget)

---@return Widget
function MatchPageVetoRow:render()
	local vetoType = self.props.vetoType
	return Div{
		classes = {
			'match-bm-game-veto-overview-team-veto-row',
			'match-bm-game-veto-overview-team-veto-row--' .. (
				vetoType == 'pick' and self.props.side or vetoType
			)
		},
		attributes = {['aria-labelledby'] = vetoType .. 's'},
		children = self.props.vetoItems
	}
end

return MatchPageVetoRow
