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

function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	unit.args.informationType = 'Car'
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	return unit:createInfobox(frame)
end

function CustomInjector:addCustomCells()
	local widgets = {
		Cell{name = 'Released', content = {_args.released}},
	}

	return widgets
end

function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

function CustomUnit:getWikiCategories(args)
	local categories = {}
	if Namespace.isMain() then
		categories = {'Cars'}
	end

	return categories
end

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

function CustomInjector:parse(_, widgets)
	return widgets
end

return CustomUnit
