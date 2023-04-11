---
-- @Liquipedia
-- wiki=commons
-- page=Module:TournamentsCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local TournamentsCard = Lua.import('Module:TournamentsCard/Base', {requireDevIfEnabled = true})

local CustomTournamentsCard = Class.new()

function CustomTournamentsCard.run(frame)
	local tournamentsCard = TournamentsCard(Arguments.getArgs(frame))

	-- you can overwrite certain functions here:
	-- tournamentsCard.addConditions = CustomTournamentsCard.addConditions

	return tournamentsCard:create():build()
end

return CustomTournamentsCard
