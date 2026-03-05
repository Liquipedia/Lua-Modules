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

local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

local CustomTournamentsListing = Class.new(TournamentsListing)

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
