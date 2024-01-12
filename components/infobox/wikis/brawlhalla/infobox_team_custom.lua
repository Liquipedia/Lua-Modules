---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team')

---@class BrawlhallaInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
