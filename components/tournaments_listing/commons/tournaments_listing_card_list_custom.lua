---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')
local TournamentsListingTable = Lua.import('Module:TournamentsListing/Display/Table')

local CustomTournamentsListing = Class.new()

---@param frame Frame
---@return Html?
function CustomTournamentsListing.run(frame)
	local args = Arguments.getArgs(frame)
	local tournamentsListing = TournamentsListing(args)

	-- you can overwrite certain functions here

	return TournamentsListingTable(tournamentsListing:create(), args):build()
end

return CustomTournamentsListing
