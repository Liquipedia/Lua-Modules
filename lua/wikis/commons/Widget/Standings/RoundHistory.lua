---
-- @Liquipedia
-- page=Module:Widget/Standings/RoundHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local RoundSelector = Lua.import('Module:Widget/Standings/RoundSelector')
local WidgetUtil = Lua.import('Module:Widget/Util')

---Wraps a standings table that has a table body per round, with a selector to switch between the rounds.
---The rows of a round have to be marked with `data-toggle-area-content = <round>`.
---@param props {activeRounds: integer, hasEnded: boolean?, titles: string[]?, controls: Renderable[]?,
---children: Renderable}
---@return Renderable
local function StandingsRoundHistory(props)
	local activeRounds = props.activeRounds
	return Html.Div{
		classes = {'standings-round-history', 'toggle-area', 'toggle-area-' .. activeRounds},
		attributes = {['data-toggle-area'] = activeRounds},
		children = {
			Html.Div{
				classes = {'standings-round-history-controls'},
				children = WidgetUtil.collect(
					RoundSelector{
						rounds = activeRounds,
						hasEnded = props.hasEnded,
						titles = props.titles,
					},
					props.controls
				),
			},
			props.children,
		},
	}
end

return Component.component(StandingsRoundHistory)
