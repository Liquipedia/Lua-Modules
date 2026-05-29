---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerStat/Container
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class MatchPagePlayerStatContainerParameters
---@field columns integer
---@field children? Renderable|Renderable[]

---@param props MatchPagePlayerStatContainerParameters
---@return Widget
local function MatchPagePlayerStatContainer(props)
	return Div{
		classes = {'match-bm-players-player-stats-container'},
		children = Div{
			classes = {
				'match-bm-players-player-stats',
				'match-bm-players-player-stats--col-' .. props.columns
			},
			children = props.children
		}
	}
end

return Component.component(MatchPagePlayerStatContainer, {columns = 6})
