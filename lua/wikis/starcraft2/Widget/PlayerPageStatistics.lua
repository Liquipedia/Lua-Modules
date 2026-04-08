---
-- @Liquipedia
-- page=Module:Widget/PlayerPageStatistics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Math = require('Module:MathUtil')
local Operator = require('Module:Operator')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local EarningsStatsChart = Lua.import('Module:Widget/EarningsStatsChart')
local MedalsTable = Lua.import('Module:Widget/MedalsTable')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class PlayerPageStatistics: Widget
---@operator call(table): PlayerPageStatistics
local PlayerPageStatistics = Class.new(Widget)

---@return Widget
function PlayerPageStatistics:render()
	return WidgetUtil.collect(
		self:_matchupStats(),
		self:_earningsChart(),
		MedalsTable{
			caption = '1v1 Medal Statistics',
			data = Json.parseIfString(Variables.varDefault('medals')),
		}
	)
end

---@return Widget?
function PlayerPageStatistics:_matchupStats()
	---@type table<string, table<string, {w: integer?, l: integer?}>>
	local data = Json.parseIfString(Variables.varDefault('matchUpStats'))
	if Logic.isEmpty(data) then
		return
	end

	local columns = Array.map(Faction.knownFactions, function(faction)
		return data.total[faction] and faction or nil
	end)
	table.insert(columns, 'total')

	local rows = {}
	for row, rowData in Table.iter.spairs(data, function(tbl, key1, key2)
		local total1 = (tbl[key1].total.w or 0) + (tbl[key1].total.l or 0)
		local total2 = (tbl[key2].total.w or 0) + (tbl[key2].total.l or 0)
		return total1 > total2
	end) do
		table.insert(rows, self:_matchupStatsRow(row, rowData, columns))
	end

	return TableWidgets.Table{
		caption = 'Matchup Statistics',
		columns = WidgetUtil.collect(
			{align = 'center'}, -- faction
			unpack(Array.map(columns, function()
				return {
					{align = 'center'}, -- Record
					{align = 'center'}, -- Win%
				}
			end))
		),
		children = {
			self:_matchupStatsHeader(columns),
			TableWidgets.TableBody{children = rows}
		},
		footer = self.props.footer
	}
end

---@param row string
---@param rowData table<string, {w: integer?, l: integer?}>
---@param columns string[]
---@return unknown
function PlayerPageStatistics:_matchupStatsRow(row, rowData, columns)
	return TableWidgets.Row{
		classes = {row ~= 'total' and Faction.bgClass(row) or nil},
		children = WidgetUtil.collect(
			TableWidgets.Cell{
				children = row == 'total' and 'Σ' or {
					'as ',
					Faction.Icon{faction = row},
				}
			},
			unpack(Array.map(columns, function(col)
				local data = rowData[col] or {}
				local sum = (data.w or 0) + (data.l or 0)
				local percent = sum == 0 and '-' or (Math.round((data.w or 0) * 100 / sum, 1) .. ' %')
				return {
					TableWidgets.Cell{
						children = {
							data.w or 0,
							' - ',
							data.l or 0
						}
					},
					TableWidgets.Cell{children = percent},
				}
			end))
		)
	}
end

---@param columns string[]
---@return Widget
function PlayerPageStatistics:_matchupStatsHeader(columns)
	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = '', rowspan = 2},
					Array.map(columns, function(col)
						local text = col == 'total' and 'Total' or ('vs ' .. Faction.Icon{faction = col})
						return TableWidgets.CellHeader{children = text, colspan = 2}
					end)
				)
			},
			TableWidgets.Row{
				children = WidgetUtil.collect(
					unpack(Array.map(columns, function(col)
						return {
							TableWidgets.CellHeader{children = 'Record'},
							TableWidgets.CellHeader{children = 'Win%'},
						}
					end))
				)
			},
		}
	}
end

---@return Widget
function PlayerPageStatistics:_earningsChart()
	local rawData = Json.parseIfString(Variables.varDefault('earningsStats')) or {}

	return EarningsStatsChart{
		data = {
			solo = Table.mapValues(rawData, Operator.property('solo')),
			team = Table.mapValues(rawData, Operator.property('team')),
			other = Table.mapValues(rawData, Operator.property('other')),
		},
		dataPoints = {
			{key = 'solo', legend = '1v1 Earnings'},
			{key = 'team', legend = 'Team Event Earnings'},
			{key = 'other', legend = 'Other Earnings'},
		},
	}
end

return PlayerPageStatistics
