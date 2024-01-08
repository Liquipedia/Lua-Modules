---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Building = Lua.import('Module:Infobox/Building', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local MODE_AVAILABILITY = {
	home 	= {order = 1, name = 'Home Village'},
	builder = {order = 2, name = 'Builder Base'},
	clan 	= {order = 3, name = 'Clan Capital'},
}

---@class ClashOfClansCustomBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = Building(frame)
	_args = building.args

	building.setLpdbData = CustomBuilding.setLpdbData
	building.createWidgetInjector = CustomBuilding.createWidgetInjector

	return building:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Cell{name = 'Range', content = {_args.range}},
		Cell{name = 'Damage Type', content = {_args.damagetype}},
		Cell{name = 'Target', content = {_args.target}},
		Cell{name = 'Favorite Target', content = {_args.favtarget}},
		Cell{name = 'Release Date', content = {_args.releasedate}}
	)

	if Table.any(_args, function(key) return MODE_AVAILABILITY[key] end) then
		table.insert(widgets, Title{name = 'Mode Availability'})
		local modeAvailabilityOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
		for key, item in Table.iter.spairs(MODE_AVAILABILITY, modeAvailabilityOrder) do
			table.insert(widgets, Cell{name = item.name, content = {_args[key]}})
		end
	end

	return widgets
end

---@return WidgetInjector
function CustomBuilding:createWidgetInjector()
	return CustomInjector()
end

---@param args table
function CustomBuilding:setLpdbData(args)
	local name = args.name or mw.title.getCurrentTitle().text
	local lpdbData = {
		type = 'building',
		name = name,
		image = args.image
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('building' .. name, lpdbData)
end

return CustomBuilding
