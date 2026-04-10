---
-- @Liquipedia
-- page=Module:Widget/MostAllKills
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')

---@class MostAllKills: Widget
---@operator call(table): MostAllKills
local MostAllKills = Class.new(Widget)

---@return Widget
function MostAllKills:render()
	return TableWidgets.Table{
		sortable = false,
		tableClasses = {'prizepooltable', 'collapsed'},
		tableAttributes = {
			['data-cutafter'] = 5,
			['data-opentext'] = 'Show more',
			['data-closetext'] = 'Show less',
		},
		columns = {
			{align = 'left'},
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = {
						TableWidgets.CellHeader{children = 'Player'},
						TableWidgets.CellHeader{children = 'All-kills'},
					}
				}
			},
			TableWidgets.TableBody{children = self:_rows()}
		},
	}
end

---@private
---@return Widget[]
function MostAllKills:_rows()
	local allKillList = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(ConditionNode(ColumnName('type'), Comparator.eq, 'allkills')),
		order = 'information desc, date desc, pagename asc',
		query = 'information, pagename',
		limit = 5000,
	})

	return Array.map(allKillList, function(allKillInfo)
		return TableWidgets.Row{
			children = {
				TableWidgets.Cell{children = self:_player(allKillInfo.pagename)},
				TableWidgets.Cell{children = allKillInfo.information},
			}
		}
	end)
end

---@private
---@param pageName string
---@return Renderable
function MostAllKills:_player(pageName)
	local playerInfo = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, pageName)),
		query = 'extradata, nationality, id',
		limit = '1',
	})[1] or {}

	return PlayerDisplay.BlockPlayer{player = {
		displayName = playerInfo.id or pageName,
		faction = (playerInfo.extradata or {}).faction,
		flag = playerInfo.nationality,
		pageName = pageName,
	}}
end

return MostAllKills
