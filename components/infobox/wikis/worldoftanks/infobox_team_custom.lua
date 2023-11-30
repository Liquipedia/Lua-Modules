---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = Team(frame)
	team.createBottomContent = CustomTeam.createBottomContent
	return team:createInfobox()
end

---@return Html
function CustomTeam:createBottomContent()
	return MatchTicker.participant{team = self.pagename}
end

return CustomTeam
