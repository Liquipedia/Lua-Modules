---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local ListingConditions = Lua.import('Module:TournamentsListing/Conditions')
local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

--- @class FightersTournamentsListing: BaseTournamentsListing
--- @operator call(...): FightersTournamentsListing
local CustomTournamentsListing = Class.new(TournamentsListing)

---@protected
---@return string
function CustomTournamentsListing:buildConditions()

	local conditions = ListingConditions.base(self.args)

	if Logic.isNotEmpty(self.args.circuit) then
		conditions:add(ConditionNode(ColumnName('circuit', 'extradata'), Comparator.eq, self.args.circuit))
	end

	if self.args.additionalConditions then
		return tostring(conditions) .. self.args.additionalConditions
	end

	return tostring(conditions)
end

---@param frame Frame
---@return Html|Widget?
function CustomTournamentsListing.run(frame)
	local args = Arguments.getArgs(frame)

	if Logic.readBool(args.byYear) then
		return CustomTournamentsListing.byYear(args)
	end

	return TournamentsListing(args):create():build()
end

return CustomTournamentsListing
