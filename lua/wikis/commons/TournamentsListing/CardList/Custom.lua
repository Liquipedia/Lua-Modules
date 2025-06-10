---
-- @Liquipedia
-- page=Module:TournamentsListing/CardList/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

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
