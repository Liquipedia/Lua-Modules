---
-- @Liquipedia
-- page=Module:Region/Ept
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local EptRegionData = mw.loadData('Module:Region/Ept/Data')
local FnUtil = require('Module:FnUtil')

--[[
Module for ESL Pro Tour regions. Each country and some dependent territories
are assigned one of three regions:
Americas
Europe & Africa
Asia & Australia

This module is used by wikis with ESL Pro Tour tournaments, which are
starcraft2, warcraft, and counterstrike.

Regions are defined in the ESL Pro Tour rulebook:
EPT Rulebook for StarCraft 2:
https://www.intelextrememasters.com/season-15/katowice/wp-content/uploads/2020/12/IEMRulebook.pdf
EOT Rulebook for CS:GO:
https://cdn.eslgaming.com/misc/media/lo/ESL%20Pro%20Tour%20-%20CSGO%20General%20Rules.pdf

]]

local EptRegion = {}

EptRegion.getRegionNamesByFlag = FnUtil.memoize(function()
	local byFlag = {}
	for _, region in ipairs(EptRegionData) do
		for _, flag in ipairs(region.countries) do
			byFlag[flag] = region.name
		end
	end
	return byFlag
end)

EptRegion.getRegion = FnUtil.memoize(function(name)
	return Array.find(EptRegionData, function(region)
		return region.name == name
	end)
end)

---@param flag string
---@return {name: string, countries: table}
function EptRegion.getByFlag(flag)
	local name = EptRegion.getRegionNamesByFlag()[flag]
	return EptRegion.getRegion(name)
end

return EptRegion
