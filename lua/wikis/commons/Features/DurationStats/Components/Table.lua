---
-- @Liquipedia
-- page=Module:Features/DurationStats/Components/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DurationStatsRow = Lua.import('Module:Features/DurationStats/Components/Row')
local DurationStatsVodLink = Lua.import('Module:Features/DurationStats/Components/VodLink')

---@param props {title: string, entries: DurationStatsEntry[]}
---@return Renderable
local function DurationStatsTable(props)
	local showVod = Array.any(props.entries, function(entry)
		return DurationStatsVodLink.getVod(entry) ~= nil
	end)

	return TableWidgets.Table{
		sortable = true,
		title = props.title,
		columns = WidgetUtil.collect(
			{align = 'left'},
			{align = 'left'},
			{align = 'right'},
			{align = 'left'},
			{align = 'left'},
			{align = 'right'},
			showVod and {align = 'center'} or nil
		),
		children = WidgetUtil.collect(
			--Header
			TableWidgets.Row{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Date', unsortable = true},
					TableWidgets.CellHeader{children = 'Stage', unsortable = true},
					TableWidgets.CellHeader{children = 'Game #', unsortable = true},
					TableWidgets.CellHeader{children = 'Winner'},
					TableWidgets.CellHeader{children = 'Loser'},
					TableWidgets.CellHeader{children = 'Duration', unsortable = true},
					showVod and TableWidgets.CellHeader{children = 'VOD', unsortable = true} or nil
				),
			},
			--Rows
			TableWidgets.TableBody{children = Array.map(props.entries, function(entry)
				return DurationStatsRow{entry = entry, showVod = showVod}
			end)}
		)
	}
end

return Component.component(DurationStatsTable)
