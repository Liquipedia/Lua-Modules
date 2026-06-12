---
-- @Liquipedia
-- page=Module:Widget/Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local FfaStandings = Lua.import('Module:Widget/Standings/Ffa')
local SwissStandings = Lua.import('Module:Widget/Standings/Swiss')

local Standings = Lua.import('Module:Standings')
local StringUtils = Lua.import('Module:StringUtils')

---@param props {pageName: string, standingsIndex: integer?}
---@return VNode?
local function StandingsWidget(props)
	local standings = Standings.getStandingsTable(props.pageName, props.standingsIndex)
	if not standings then
		return
	end

	local standingsWidget
	if standings.type == 'ffa' then
		standingsWidget = FfaStandings{
			standings = standings,
		}
	elseif standings.type == 'swiss' then
		standingsWidget = SwissStandings{
			standings = standings,
		}
	end

	assert(standingsWidget, 'This Standings Type not yet implemented')

	return AnalyticsWidget{
		analyticsName = StringUtils.upperCaseFirst(standings.type) .. ' standings table',
		children = standingsWidget
	}

end

return Component.component(StandingsWidget)
