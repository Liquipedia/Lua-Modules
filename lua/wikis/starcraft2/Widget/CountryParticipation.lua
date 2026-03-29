local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')

---@class CountryParticipation: Widget
---@operator call(table): CountryParticipation
local CountryParticipation = Class.new(Widget)

function CountryParticipation:render()
	return TableWidgets.Table{
		sortable = true,
		columns = {
			{align = 'left'},
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = 'Country'},
							TableWidgets.CellHeader{children = '#Players'},
						}
					}
				}
			},
			TableWidgets.TableBody{children = Array.map(self:_fetch(), CountryParticipation._row)}
		},
	}
end

---@param data {flag: string, count: integer}
---@return Widget
function CountryParticipation._row(data)
	return TableWidgets.Row{
		children = {
			TableWidgets.Cell{
				children = {
					Flags.Icon{flag = data.flag, shouldLink = false},
					'&nbsp;',
					data.flag,
				}
			},
			TableWidgets.Cell{children = data.count},
		}
	}
end

---@return {flag: string, count: integer}[]
function CountryParticipation:_fetch()
	local pageNames = Array.flatten((TournamentStructure.readMatchGroupsSpec(self.props)
		or TournamentStructure.currentPageSpec()).pageNames)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('name'), Comparator.neq, ''),
		TournamentStructure.getPageNamesFilter('bracket', pageNames),
	}

	local queryData = mw.ext.LiquipediaDB.lpdb('match2player', {
		conditions = tostring(conditions),
		groupby = 'name asc',
		query = 'flag',
		limit = 5000
	})

	---@type table<string, {flag: string, count: integer}>
	local flags = {}
	Array.forEach(queryData, function(item)
		local flag = item.flag
		if not flags[flag] then
			flags[flag] = {flag = flag, count = 0}
		end
		flags[flag].count = flags[flag].count + 1
	end)

	---@type {flag: string, count: integer}[]
	local data = Array.extractValues(flags)
	table.sort(data, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.flag < b.flag
	end)

	return data
end

return CountryParticipation
