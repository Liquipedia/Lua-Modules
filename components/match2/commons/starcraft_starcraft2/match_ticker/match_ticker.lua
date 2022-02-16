---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')

local Condition = require('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local MatchTicker = Class.new()

MatchTicker.Display = Lua.import('Module:MatchTicker/Display', {requireDevIfEnabled = true})

MatchTicker.Query = Lua.import('Module:MatchTicker/Query', {requireDevIfEnabled = true})

MatchTicker.HelperFunctions = Lua.import('Module:MatchTicker/Helpers/Custom', {requireDevIfEnabled = true})

--overwrite stuff
function MatchTicker.Query.BaseConditions:build(queryArgs)
	if Logic.readBool(queryArgs.featured) then
		self.conditionTree:add({ConditionNode(ColumnName('extradata_featured'), Comparator.eq, 'true')})
	end

	return self.conditionTree
end


return MatchTicker
