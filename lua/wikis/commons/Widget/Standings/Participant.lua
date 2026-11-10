---
-- @Liquipedia
-- page=Module:Widget/Standings/Participant
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Label = Lua.import('Module:Widget/Basic/Label')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@param props {opponent: standardOpponent, disqualified: boolean?}
---@return Renderable
local function StandingsParticipant(props)
	local opponentDisplay = OpponentDisplay.BlockOpponent{
		opponent = props.opponent,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
		showPlayerTeam = true,
		dq = props.disqualified,
	}
	if not props.disqualified then
		return opponentDisplay
	end
	return Html.Div{
		classes = {'standings-participant'},
		children = {
			opponentDisplay,
			Label{
				children = 'DQ',
				attributes = {['data-placement-type'] = 'dq'},
				labelScheme = 'placement',
			},
		},
	}
end

return Component.component(StandingsParticipant)
