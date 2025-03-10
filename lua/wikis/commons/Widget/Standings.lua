---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Standings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local FfaStandings = Lua.import('Module:Widget/Standings/Ffa')
local SwissStandings = Lua.import('Module:Widget/Standings/Swiss')

local Standings = Lua.import('Module:Standings')

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

	if standings.type == 'ffa' then
		return FfaStandings{
			standings = standings,
		}
	elseif standings.type == 'swiss' then
		return SwissStandings{
			standings = standings,
		}
	end
	error('This Standings Type not yet implemented')
end

return StandingsWidget
