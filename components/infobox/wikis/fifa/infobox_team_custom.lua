---
-- @Liquipedia
-- wiki=fifa
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	team.createBottomContent = CustomTeam.createBottomContent
	return team:createInfobox()
end

function CustomTeam:createBottomContent()
	return MatchTicker.participant{team = self.pagename}
end

return CustomTeam
