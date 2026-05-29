---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerStat
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {title: Renderable|Renderable[], data?: Renderable|Renderable[]}
---@return VNode
local function MatchPagePlayerStat(props)
	local title = props.title
	local data = props.data
	assert(Logic.isNotEmpty(title), 'Title not specified for this stat')
	data = Logic.emptyOr(data, '?')
	return Div{
		classes = {'match-bm-players-player-stat'},
		children = {
			Div{
				classes = {'match-bm-players-player-stat-title'},
				children = title
			},
			Div{
				classes = {'match-bm-players-player-stat-data'},
				children = data
			}
		}
	}
end

return Component.component(MatchPagePlayerStat)
