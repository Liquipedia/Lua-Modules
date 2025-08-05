---
-- @Liquipedia
-- page=Module:Infobox/Unit/Tank/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local TankTypes = require('Module:TankTypes')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Nation = Lua.import('Module:Infobox/Extension/Nation')

local Widgets = require('Module:Widget/All')
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
			Cell{name = 'Released', content = {args.released}},
			Cell{name = 'Technical Name', content = {args.techname}},
			Cell{name = 'Tank Type', content = {CustomUnit._getTankType(args)}},
			Cell{name = 'Tank Tier', content = {args.tier}},
			Cell{name = 'Nation', content = {Nation.run(args.nation)}},
			Cell{name = 'Role', content = {args.role}}
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
