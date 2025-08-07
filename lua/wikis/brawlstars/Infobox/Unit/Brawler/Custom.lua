---
-- @Liquipedia
-- page=Module:Infobox/Unit/Brawler/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
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
			Cell{name = 'Real Name', children = {args.realname}},
			Cell{name = 'Rarity', children = {args.rarity}},
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Unlock', children = {args.unlock}},
		}
	elseif id == 'attack' then
		return {}
	elseif id == 'defense' then
		return {}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Release Date', children = {args.releasedate}},
			Cell{name = 'Health', children = {args.hp}},
			Cell{name = 'Movespeed', children = {args.movespeed}},
			Title{children = 'Weapon & Super'},
			Cell{name = 'Primary Weapon', children = {args.attack}},
			Cell{name = 'Super Ability', children = {args.super}},
			Title{children = 'Abilities'},
			Cell{name = 'Gadgets', children = {args.gadget}},
			Cell{name = 'Star Powers', children = {args.star}},
			Cell{name = 'Hypercharge', children = {args.hypercharge}}
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
