---
-- @Liquipedia
-- page=Module:MatchTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Custom')

local MatchTable = Lua.import('Module:MatchTable')

local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'

local CustomMatchTable = {}

---@param args table
---@return Html
function CustomMatchTable.results(args)
	args.showRoundStats = Logic.nilOr(Logic.readBoolOrNil(args.showRoundStats), true)
	args.gameIcons = Logic.nilOr(Logic.readBoolOrNil(args.gameIcons), true)
	args.vod = Logic.nilOr(Logic.readBoolOrNil(args.vod), true)
	args.showType = Logic.nilOr(Logic.readBoolOrNil(args.showType), true)

	local matchtable = MatchTable(args)
	matchtable._displayTier = CustomMatchTable._displayTier

	return matchtable:readConfig():query():build()
end

---@param match MatchTableMatch
---@return Html?
function CustomMatchTable:_displayTier(match)
	if not self.config.showTier then return end

	local tier, tierType, options = Tier.parseFromQueryData(match)
	options.link = true
	options.onlyDisplayPrioritized = true

	if not Tier.isValid(tier, tierType) then
		return mw.html.create('td')
			:attr('data-sort-value', INVALID_TIER_DISPLAY)
			:wikitext(INVALID_TIER_SORT)
	end

	return mw.html.create('td')
		:attr('data-sort-value', Tier.toSortValue(tier, tierType))
		:wikitext(Tier.display(tier, tierType, options))
end

return Class.export(CustomMatchTable, {exports = {'results'}})
