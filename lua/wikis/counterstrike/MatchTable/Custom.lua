---
-- @Liquipedia
-- page=Module:MatchTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Tier = Lua.import('Module:Tier/Custom')

local MatchTable = Lua.import('Module:MatchTable')

local TableWidgets = Lua.import('Module:Widget/Table2/All')

local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

---@class CounterstrikeMatchTable: MatchTable
---@operator call(table): CounterstrikeMatchTable
local CustomMatchTable = Class.new(MatchTable)

---@param args table
---@return Widget
function CustomMatchTable.results(args)
	args.showRoundStats = Logic.nilOr(Logic.readBoolOrNil(args.showRoundStats), true)
	args.gameIcons = Logic.nilOr(Logic.readBoolOrNil(args.gameIcons), true)
	args.vod = Logic.nilOr(Logic.readBoolOrNil(args.vod), true)
	args.showType = Logic.nilOr(Logic.readBoolOrNil(args.showType), true)

	return CustomMatchTable(args):readConfig():query():build()
end

---@protected
---@param match MatchTableMatch
---@return Widget?
function CustomMatchTable:displayTier(match)
	if not self.config.showTier then return end

	local tier, tierType, options = Tier.parseFromQueryData(match)
	options.link = true
	options.onlyDisplayPrioritized = true

	if not Tier.isValid(tier, tierType) then
		return TableWidgets.Cell{
			attributes = {['data-sort-value'] = INVALID_TIER_SORT},
			children = INVALID_TIER_DISPLAY
		}
	end

	return TableWidgets.Cell{
		attributes = {['data-sort-value'] = Tier.toSortValue(tier, tierType)},
		children = Tier.display(tier, tierType, options)
	}
end

return Class.export(CustomMatchTable, {exports = {'results'}})
