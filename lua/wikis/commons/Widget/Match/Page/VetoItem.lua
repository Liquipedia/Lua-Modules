---
-- @Liquipedia
-- page=Module:Widget/Match/Page/VetoItem
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageVetoItemParameters
---@field characterIcon (string|Html|Widget|nil)
---@field vetoNumber integer?

---@class MatchPageVetoItem: Widget
---@operator call(MatchPageVetoItemParameters): MatchPageVetoItem
---@field props MatchPageVetoItemParameters
local MatchPageVetoItem = Class.new(Widget)

---@return Widget
function MatchPageVetoItem:render()
	local vetoNumber = self.props.vetoNumber
	return Div{
		classes = {'match-bm-game-veto-overview-team-veto-row-item'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-veto-row-item-icon'},
				children = self.props.characterIcon
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto-row-item-text'},
				children = vetoNumber and {'#', vetoNumber} or ''
			}
		}
	}
end

return MatchPageVetoItem
