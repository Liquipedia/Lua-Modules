---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

---@class OverwatchInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Widget
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return Widget?
function CustomTeam:createBottomContent()
	return UpcomingTournaments.team{name = self.teamTemplate.templatename}
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.competesin = string.upper(args.league or '')

	return lpdbData
end

---@param args table
---@return string[]
function CustomTeam:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.league) then
		table.insert(categories, string.upper(args.league) .. ' Teams')
	end

	return categories
end

return CustomTeam
