---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Class = require('Module:Class')

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	team.addToLpdb = CustomTeam.addToLpdb

	return team:createInfobox(frame)
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
