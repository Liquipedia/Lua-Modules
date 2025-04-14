---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/TeamVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageTeamVetoParameters
---@field teamIcon (string|Html|Widget|nil)
---@field vetoRows MatchPageVetoRow[]

---@class MatchPageTeamVeto: Widget
---@operator call(MatchPageTeamVetoParameters): MatchPageTeamVeto
---@field props MatchPageTeamVetoParameters
local MatchPageTeamVeto = Class.new(Widget)

---@return Widget
function MatchPageTeamVeto:render()
	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-header'},
				children = self.props.teamIcon
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto'},
				children = self.props.vetoRows
			}
		}
	}
end

return MatchPageTeamVeto
