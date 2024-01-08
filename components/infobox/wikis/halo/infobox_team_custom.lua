---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Region = require('Module:Region')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class HaloInfoboxTeam: InfoboxTeam
---@field region {display: string?, region: string?}
local CustomTeam = Class.new(Team)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	team.region = Region.run({region = team.args.region, country = team:getStandardLocationValue(team.args.location)})

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'region' then
		return {
			Cell{name = 'Region', content = {self.caller.region.display}}
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = self.region.region

	return lpdbData
end

return CustomTeam
