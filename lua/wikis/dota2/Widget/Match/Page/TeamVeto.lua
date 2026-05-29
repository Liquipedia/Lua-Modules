---
-- @Liquipedia
-- page=Module:Widget/Match/Page/TeamVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class Dota2MatchPageTeamVetoParameters
---@field teamIcon Renderable?
---@field vetoRows VNode[]

---@param props Dota2MatchPageTeamVetoParameters
---@return Widget
local function MatchPageTeamVeto(props)
	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-header'},
				children = props.teamIcon
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto'},
				children = props.vetoRows
			}
		}
	}
end

return Component.component(MatchPageTeamVeto)
