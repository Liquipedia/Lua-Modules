---
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch/Fetch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Lpdb = Lua.import('Module:Lpdb')


local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local PatchFetch = {}

-- Fetches patch data from the Liquipedia database based on provided arguments
---@param config {game: string?, startDate: integer?, endDate: integer?, year: integer?, limit: integer?}
---@return datapoint[]
function PatchFetch.run(config)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'patch'),
		config.game and ConditionNode(ColumnName('extradata_game'), Comparator.eq, config.game) or nil,
		config.year and ConditionNode(ColumnName('date_year'), Comparator.eq, config.year) or nil,
		config.startDate and ConditionNode(ColumnName('date'), Comparator.ge, config.startDate) or nil,
		config.endDate and ConditionNode(ColumnName('date'), Comparator.le, config.endDate) or nil,
	}

	local patches = {}
	Lpdb.executeMassQuery('datapoint', {
		conditions = conditions:toString(),
		order = 'date desc, pagename desc',

	}, function(patch)
		table.insert(patches, patch)
	end, tonumber(config.limit) or 100)

	return patches
end

return PatchFetch
