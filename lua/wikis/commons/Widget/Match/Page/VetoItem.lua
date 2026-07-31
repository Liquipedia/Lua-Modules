---
-- @Liquipedia
-- page=Module:Widget/Match/Page/VetoItem
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class MatchPageVetoItemProps
---@field characterIcon Renderable?
---@field vetoNumber integer?

---@param props MatchPageVetoItemProps
---@return VNode
local function MatchPageVetoItem(props)
	local vetoNumber = props.vetoNumber
	return Div{
		classes = {'match-bm-game-veto-overview-team-veto-row-item'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-veto-row-item-icon'},
				children = props.characterIcon
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto-row-item-text'},
				children = vetoNumber and {'#', vetoNumber} or ''
			}
		}
	}
end

return Component.component(MatchPageVetoItem)
