---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Unit/Tank
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local TankTypes = require('Module:TankTypes')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})
local Nation = Lua.import('Module:Infobox/Extension/Nation', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _pagename = mw.title.getCurrentTitle().text

local _args

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.append(widgets,
		Cell{name = 'Released', content = {_args.released}},
		Cell{name = 'Technical Name', content = {_args.techname}},
		Cell{name = 'Tank Type', content = {CustomUnit._getTankType()}},
		Cell{name = 'Tank Tier', content = {_args.tier}},
		Cell{name = 'Nation', content = {Nation.run(_args.nation)}},
		Cell{name = 'Role', content = {_args.role}}
	)
end

---@return string[]
function CustomUnit._getTankType()
	if String.isEmpty(_args.tanktype) then
		return {}
	end

	local releasedate = _args.releasedate
	local typeIcon = TankTypes.get{type = _args.tanktype, date = releasedate, size = 15}
	return typeIcon .. ' [[' .. _args.tanktype .. ']]'
end

---@return WidgetInjector
function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local categories = {}
	if Namespace.isMain() then
		categories = {'Tanks'}
	end

	return categories
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or _pagename,
		type = 'tank',
		image = args.image,
		date = args.released,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			technicalname = args.techname,
			tanktier = args.tier,
			nation = args.nation,
			tankrole = args.role,
			tanktype = args.tanktype
		}
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('tank_' .. (args.name or _pagename), lpdbData)
end

return CustomUnit
