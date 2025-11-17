---
-- @Liquipedia
-- page=Module:Infobox/Unit/Tank/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local TankTypes = Lua.import('Module:TankTypes')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Nation = Lua.import('Module:Infobox/Extension/Nation')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class WorldofTanksUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Tank'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return Array.append(widgets,
			Cell{name = 'Released', children = {args.released}},
			Cell{name = 'Technical Name', children = {args.techname}},
			Cell{name = 'Tank Type', children = {CustomUnit._getTankType(args)}},
			Cell{name = 'Tank Tier', children = {args.tier}},
			Cell{name = 'Nation', children = {Nation.run(args.nation)}},
			Cell{name = 'Role', children = {args.role}}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomUnit._getTankType(args)
	if String.isEmpty(args.tanktype) then
		return {}
	end
	local releasedate = args.releasedate
	local typeIcon = TankTypes.get{type = args.tanktype, date = releasedate, size = 15}
	return typeIcon .. ' [[' .. args.tanktype .. ']]'
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	local categories = {'Tanks'}
	if String.isEmpty(args.tanktype) then
		return categories
	end
	return Array.append(categories, args.tanktype .. ' Tanks')
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or self.pagename,
		type = 'tank',
		image = args.image,
		date = args.released,
		information = 'tank',
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			technicalname = args.techname,
			tanktier = args.tier,
			nation = args.nation,
			tankrole = args.role,
			tanktype = args.tanktype
		}
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('tank_' .. (args.name or self.pagename), lpdbData)
end

return CustomUnit
