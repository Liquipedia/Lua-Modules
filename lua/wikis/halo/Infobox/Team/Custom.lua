---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Region = require('Module:Region')

local Team = Lua.import('Module:Infobox/Team')

---@class HaloInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@param region string?
---@return {display: string?, region: string?}
function CustomTeam:createRegion(region)
	return Region.run({region = region, country = self:getStandardLocationValue(self.args.location)})
end

return CustomTeam
