---
-- @Liquipedia
-- page=Module:Features/SeriesMedalStatistics/Components/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Types = Lua.import('Module:Features/SeriesMedalStatistics/Types')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {statsType: string}
---@return VNode?
local render = function(props)
	local statsType = props.statsType
	if statsType ~= Types.statsTypes.PARTICIPANT_TEAM then
		return
	end
	return Html.Small{
		children = {
			'Medals won per Team shows the team that a player was',
			Html.Br{},
			'on when the medal was won, ',
			Html.B{children = 'not'},
			' their current team.',
		}
	}
end

return Component.component(render)
