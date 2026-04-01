local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = require('Module:Json')
local Variables = require('Module:Variables')

local Box = Lua.import('Module:Widget/Basic/Box')
local EarningsStatsChart = Lua.import('Module:Widget/EarningsStatsChart')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MedalsTable = Lua.import('Module:Widget/MedalsTable')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TeamPageStatistics: Widget
---@operator call(table): TeamPageStatistics
local TeamPageStatistics = Class.new(Widget)

---@return Widget
function TeamPageStatistics:render()
	return WidgetUtil.collect(
		self:_earningsChart(),
		self:_medalTables()
	)
end

---@return Widget
function TeamPageStatistics:_earningsChart()
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

---@return Widget
function TeamPageStatistics:_medalTables()
	local data = Json.parseIfString(Variables.varDefault('medals'))
	return Box{
		paddingRight = '2em',
		children = WidgetUtil.collect(
			MedalsTable{
				caption = 'Team Medal Statistics',
				data = data.team,
			},
			MedalsTable{
				caption = '1v1 Medal Statistics',
				data = data.solo,
				footer = HtmlWidgets.Small{
					children = {
						HtmlWidgets.B{children = 'Note:'},
						' This table shows the medals won by players in 1v1 events while on the team.'
					}
				},
			}
		),
	}
end

return TeamPageStatistics
