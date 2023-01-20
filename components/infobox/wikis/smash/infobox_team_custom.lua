---
-- @Liquipedia
-- wiki=smash
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Team = require('Module:Infobox/Team')

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox(frame)
end

function CustomTeam:addToLpdb(lpdbData)
	lpdbData.region = nil

	return lpdbData
end

return CustomTeam
