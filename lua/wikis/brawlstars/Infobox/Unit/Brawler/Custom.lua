---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Unit/Brawler/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class BrawlStarsUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Brawler'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'caption' and not String.isEmpty(args.min) then
		table.insert(widgets, Center{children = {args.quote}})
	elseif id == 'type' then
		return {
			Cell{name = 'Real Name', content = {args.realname}},
			Cell{name = 'Rarity', content = {args.rarity}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Unlock', content = {args.unlock}},
		}
	elseif id == 'attack' then
		return {}
	elseif id == 'defense' then
		return {}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Release Date', content = {args.releasedate}},
			Cell{name = 'Health', content = {args.hp}},
			Cell{name = 'Movespeed', content = {args.movespeed}},
			Title{children = 'Weapon & Super'},
			Cell{name = 'Primary Weapon', content = {args.attack}},
			Cell{name = 'Super Ability', content = {args.super}},
			Title{children = 'Abilities'},
			Cell{name = 'Gadgets', content = {args.gadget}},
			Cell{name = 'Star Powers', content = {args.star}},
			Cell{name = 'Hypercharge', content = {args.hypercharge}}
		)
	end

	return widgets
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or self.pagename,
		type = 'brawler',
		image = args.image,
		date = args.releasedate,
		information = 'brawler',
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{}
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('brawler_' .. (args.name or self.pagename), lpdbData)
end

---@param args table
---@return table
function CustomUnit:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.append({'Brawlers'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' brawlers') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' brawlers') or nil
	)
end

return CustomUnit
