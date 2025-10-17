---
-- @Liquipedia
-- page=Module:Widget/Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local FfaStandings = Lua.import('Module:Widget/Standings/Ffa')
local SwissStandings = Lua.import('Module:Widget/Standings/Swiss')

local Standings = Lua.import('Module:Standings')
local StringUtils = Lua.import('Module:StringUtils')

---@class StandingsWidget: Widget
---@operator call(table): StandingsWidget
local StandingsWidget = Class.new(Widget)
StandingsWidget.defaultProps = {
}

---@return Widget?
function StandingsWidget:render()
	local standings = Standings.getStandingsTable(self.props.pageName, self.props.standingsIndex)
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

	if standingsWidget then
		return AnalyticsWidget{
			analyticsName = StringUtils.upperCaseFirst(standings.type) .. ' standings table',
			children = standingsWidget
		}
	end

	error('This Standings Type not yet implemented')
end

return StandingsWidget
