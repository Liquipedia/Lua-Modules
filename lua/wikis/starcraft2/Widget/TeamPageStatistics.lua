---
-- @Liquipedia
-- page=Module:Widget/TeamPageStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Json = Lua.import('Module:Json')
local Variables = Lua.import('Module:Variables')

local Box = Lua.import('Module:Widget/Basic/Box')
local Component = Lua.import('Module:Widget/Component')
local EarningsStatsChart = Lua.import('Module:Widget/EarningsStatsChart')
local Html = Lua.import('Module:Widget/Html')
local MedalsTable = Lua.import('Module:Widget/MedalsTable')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TeamPageStatistics = {}

---@return VNode
function TeamPageStatistics.render()
	return WidgetUtil.collect(
		TeamPageStatistics._earningsChart(),
		TeamPageStatistics._medalTables()
	)
end

---@return VNode
function TeamPageStatistics._earningsChart()
	return EarningsStatsChart{
		data = {
			solo = Json.parseIfString(Variables.varDefault('playerEarnings')) or {},
			team = Json.parseIfString(Variables.varDefault('teamEarnings')) or {},
		},
		dataPoints = {
			{key = 'team', legend = 'Team Earnings'},
			{key = 'solo', legend = 'Player (non-Team Event) Earnings while on the Team'},
		},
	}
end

---@return VNode
function TeamPageStatistics._medalTables()
	local data = Json.parseIfString(Variables.varDefault('medals'))
	return Box{
		children = {
			MedalsTable{
				caption = 'Team Medal Statistics',
				data = data.team,
			},
			MedalsTable{
				caption = '1v1 Medal Statistics',
				data = data.solo,
				footer = Html.Small{
					children = {
						Html.B{children = 'Note:'},
						' This table shows the medals won by players in 1v1 events while on the team.'
					}
				},
			}
		},
	}
end

return Component.component(TeamPageStatistics.render)
