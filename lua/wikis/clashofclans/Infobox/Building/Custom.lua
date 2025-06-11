---
-- @Liquipedia
-- page=Module:Infobox/Building/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Building = Lua.import('Module:Infobox/Building')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local MODE_AVAILABILITY = {
	home 	= {order = 1, name = 'Home Village'},
	builder = {order = 2, name = 'Builder Base'},
	clan 	= {order = 3, name = 'Clan Capital'},
}

---@class ClashofclansBuildingInfobox: BuildingInfobox
local CustomBuilding = Class.new(Building)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomBuilding.run(frame)
	local building = CustomBuilding(frame)
	building:setWidgetInjector(CustomInjector(building))

	return building:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Range', content = {args.range}},
			Cell{name = 'Damage Type', content = {args.damagetype}},
			Cell{name = 'Target', content = {args.target}},
			Cell{name = 'Favorite Target', content = {args.favtarget}},
			Cell{name = 'Release Date', content = {args.releasedate}}
		)

		if Table.any(args, function(key) return MODE_AVAILABILITY[key] end) then
			table.insert(widgets, Title{children = 'Mode Availability'})
			local modeAvailabilityOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
			for key, item in Table.iter.spairs(MODE_AVAILABILITY, modeAvailabilityOrder) do
				table.insert(widgets, Cell{name = item.name, content = {args[key]}})
			end
		end
	end

	return widgets
end

---@param args table
function CustomBuilding:setLpdbData(args)
	local name = args.name or self.pagename
	local lpdbData = {
		type = 'building',
		name = name,
		image = args.image
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('building' .. name, lpdbData)
end

return CustomBuilding
