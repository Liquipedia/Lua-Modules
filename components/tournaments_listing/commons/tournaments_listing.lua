---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsListing
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TournamentsListing = Lua.import('Module:TournamentsListing/Base', {requireDevIfEnabled = true})

local CustomTournamentsListing = Class.new()

function CustomTournamentsListing.run(frame)
	local tournamentsListing = TournamentsListing(Arguments.getArgs(frame))

	-- you can overwrite certain functions here:
	-- tournamentsListing.addConditions = CustomTournamentsListing.addConditions

	return tournamentsListing:create():build()
end

return CustomTournamentsListing
