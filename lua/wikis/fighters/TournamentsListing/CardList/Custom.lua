---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local ListingConditions = Lua.import('Module:TournamentsListing/Conditions')
local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local DEFAULT_START_YEAR = Info.startYear
local DEFAULT_END_YEAR = DateExt.getYearOf()

--- @class FightersTournamentsListing: BaseTournamentsListing
--- @operator call(...): FightersTournamentsListing
local CustomTournamentsListing = Class.new(TournamentsListing)

---@protected
---@return string
function CustomTournamentsListing:buildConditions()

	local conditions = ListingConditions.base(self.args)

	if Logic.isNotEmpty(self.args.circuit) then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('circuit', 'extradata'), Comparator.eq, self.args.circuit),
				ConditionUtil.anyOf(
					ColumnName('circuit_tier', 'extradata'), Array.parseCommaSeparatedString(self.args.circuittier)
				)
			},
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('circuit2', 'extradata'), Comparator.eq, self.args.circuit),
				ConditionUtil.anyOf(
					ColumnName('circuit2_tier', 'extradata'), Array.parseCommaSeparatedString(self.args.circuittier)
				)
			}
		})
	end

	if self.args.additionalConditions then
		return tostring(conditions) .. self.args.additionalConditions
	end

	return tostring(conditions)
end

---@param args table
---@return Widget?
function CustomTournamentsListing.byYear(args)
	args = args or {}

	args.order = 'enddate desc'

	local subPageName = mw.title.getCurrentTitle().subpageText
	local fallbackYearData = {}
	if subPageName:find('%d%-%d') then
		fallbackYearData = Array.parseCommaSeparatedString(subPageName, '-')
	end

	local startYear = tonumber(args.startYear) or tonumber(fallbackYearData[1]) or DEFAULT_START_YEAR
	local endYear = tonumber(args.endYear) or tonumber(fallbackYearData[2]) or DEFAULT_END_YEAR

	local children = {}
	Array.forEach(Array.reverse(Array.range(startYear, endYear)), function(year)
		local tournaments = CustomTournamentsListing(Table.merge(args, {year = year})):create():build()
		if not tournaments then return end
		Array.appendWith(children,
			HtmlWidgets.H3{children = year},
			tournaments
		)
	end)

	return HtmlWidgets.Fragment{children = children}
end

---@param frame Frame
---@return Html|Widget?
function CustomTournamentsListing.run(frame)
	local args = Arguments.getArgs(frame)

	args.showGameIcon = Logic.nilOr(Logic.readBoolOrNil(args.showGameIcon), Logic.isEmpty(args.game))

	if Logic.readBool(args.byYear) then
		return CustomTournamentsListing.byYear(args)
	end

	return CustomTournamentsListing(args):create():build()
end

return CustomTournamentsListing
