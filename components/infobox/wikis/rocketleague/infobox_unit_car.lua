---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Unit/Car
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	unit.args.informationType = 'Car'
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Released', content = {_args.released}},
	}
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
		categories = {'Cars'}
	end

	return categories
end

---@param args table
function CustomUnit:setLpdbData(args)
	local game = args.game or 'rl'
	if game == 'rl' then
		game = 'rocketleague'
	end
	local lpdbData = {
		name = args.name,
		type = 'car',
		image = args.image,
		date = args.released,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			game = game,
		}),
	}

	-- Wikicode was: car_{{#explode:{{PAGENAME}}|/|1}}
	local objectName = mw.title.getCurrentTitle().text
	objectName = string.gsub(objectName, '.-/^', '')
	objectName = string.gsub(objectName, '/.*$', '')
	objectName = 'car_' .. objectName

	mw.ext.LiquipediaDB.lpdb_datapoint(objectName, lpdbData)
end

return CustomUnit
