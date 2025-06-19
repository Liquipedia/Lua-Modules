---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local TournamentsListing = Lua.import('Module:TournamentsListing/CardList')

local CustomTournamentsListing = Class.new()

---@param frame Frame
---@return Html?
function CustomTournamentsListing.run(frame)
	local tournamentsListing = TournamentsListing(Arguments.getArgs(frame))

	-- you can overwrite certain functions here

	return tournamentsListing:create():build()
end

return CustomTournamentsListing
