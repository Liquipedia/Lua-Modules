---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Unit/Brawler
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local _brawlerName
local _args

local CustomUnit = Class.new()

local CustomInjector = Class.new(Injector)

function CustomUnit.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	unit.args.informationType = 'Brawler'
	unit.nameDisplay = CustomUnit.nameDisplay
	unit.setLpdbData = CustomUnit.setLpdbData
	unit.getWikiCategories = CustomUnit.getWikiCategories
	unit.createWidgetInjector = CustomUnit.createWidgetInjector
	return unit:createInfobox(frame)
end

function CustomInjector:addCustomCells()
	local widgets = {
		Cell{name = 'Release Date', content = {_args.releasedate}},
		Cell{name = 'Health', content = {_args.hp}},
		Cell{name = 'Movespeed', content = {_args.movespeed}},
		Title{name = 'Weapon & Super'},
		Cell{name = 'Primary Weapon', content = {_args.attack}},
		Cell{name = 'Super Ability', content = {_args.super}},
		Title{name = 'Gadgets & Star Powers'},
		Cell{name = 'Gadgets', content = {_args.gadget}},
		Cell{name = 'Star Powers', content = {_args.star}},
	}

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'caption' and not String.isEmpty(_args.min) then
		table.insert(widgets, Center{content = {_args.quote}})
	elseif id == 'type' then
		return {
			Cell{name = 'Real Name', content = {_args.realname}},
			Cell{name = 'Rarity', content = {_args.rarity}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Unlock', content = {_args.unlock}},
		}
	elseif id == 'attack' then
		return {}
	elseif id == 'defense' then
		return {}
	end
	return widgets
end

function CustomUnit:createWidgetInjector()
	return CustomInjector()
end

function CustomUnit:nameDisplay()
	_brawlerName = Template.safeExpand(mw.getCurrentFrame(), 'brawlername', {self.pagename}, self.pagename)

	return _brawlerName
end

function CustomUnit:setLpdbData(args)
	Template.safeExpand(mw.getCurrentFrame(), 'HeroData', {name = _brawlerName, image = _args.image}, self.pagename)
end

function CustomUnit:getWikiCategories(args)
	local categories = {}
	if Namespace.isMain() then
		categories = {'Brawlers'}
		if not String.isEmpty(args.attacktype) then
			table.insert(categories, args.attacktype .. ' brawlers')
		end
		if not String.isEmpty(args.primaryrole) then
			table.insert(categories, args.primaryrole .. ' brawlers')
		end
	end

	return categories
end

return CustomUnit
