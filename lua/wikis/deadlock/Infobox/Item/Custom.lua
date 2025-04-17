---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class DeadlockItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION = '_positiveConcatedArgsForBase'

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item.args.image = item.args.image or ('Deadlock_gameasset_Item ' .. item.args.name .. '.png')
	item.args.subheader = item:_getCostDisplay()
	item.args.imagesize = 100
	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args
	if id == 'attributes' then
		local attributeCells = {
			{name = 'Health', parameter = 'hp'},
			{name = 'Bonus Health', parameter = 'bonushp'},
			{name = 'Health Regen', parameter = 'hpregen'},
			{name = 'Max Health', parameter = 'maxhp'},
			{name = 'Mana', parameter = 'mana'},
			{name = 'Mana Regen', parameter = 'manaregen'},
			{name = 'Ammo', parameter = 'ammo'},
			{name = 'Weapon Damage', parameter = 'weapondmg', funct = '_positivePercentDisplay'},
			{name = 'Weapon Damage vs. NPCs', parameter = 'weapondmgnpc', funct = '_positivePercentDisplay'},
			{name = 'Weapon Fall-off range', parameter = 'weaponfalloff', funct = '_positivePercentDisplay'},
			{name = 'Weapon Zoom', parameter = 'weaponzoom', funct = '_positivePercentDisplay'},
			{name = 'Fire Rate', parameter = 'firerate', funct = '_positivePercentDisplay'},
			{name = 'Bullet Velocity', parameter = 'velocity', funct = '_positivePercentDisplay'},
			{name = 'Bullet Lifesteal', parameter = 'bulletlifesteal', funct = '_positivePercentDisplay'},
			{name = 'Bullet Slow Proc', parameter = 'bulletslow', funct = '_positivePercentDisplay'},
			{name = 'Reload Time', parameter = 'reload', funct = '_positivePercentDisplay'},
			{name = 'Bullet Shield Health', parameter = 'bulletshield'},
			{name = 'Bullet Resist', parameter = 'bulletresist', funct = '_positivePercentDisplay'},
			{name = 'Bullet Resist vs. NPCs', parameter = 'bulletresistnpc', funct = '_positivePercentDisplay'},
			{name = 'Sprint Speed', parameter = 'sprintspeed'},
			{name = 'Stamina', parameter = 'Stamina'},
			{name = 'Slide Distance', parameter = 'slidedistance', funct = '_positivePercentDisplay'},
			{name = 'Spirit Power', parameter = 'spiritpower'},
			{name = 'Spirit Resist', parameter = 'spiritresist'},
			{name = 'Spirit Shield Health', parameter = 'spiritshield'},
			{name = 'Spirit Lifesteal', parameter = 'spiritlifesteal', funct = '_positivePercentDisplay'},
			{name = 'Cooldown Reduction', parameter = 'cdreduction', funct = '_positivePercentDisplay'},
			{name = 'Movement Speed', parameter = 'movespeed'},
		}
		widgets = caller:_getAttributeCells(attributeCells)
		table.insert(widgets, Cell{name = 'Standard Bonus', children = {args.standardbonus}})
		if Table.isNotEmpty(widgets) then
			table.insert(widgets, 1, Title{children = 'Attributes'})
		end
		return widgets
	elseif id == 'ability' then
		if String.isEmpty(args.active) and String.isEmpty(args.passive) then
			return {}
		end
		Array.appendWith(widgets,
			Cell{name = 'Active', children = {args.active, args.active2, args.active3}},
			Cell{name = 'Passive', children = {args.passive, args.passive2, args.passive3}}
		)
	elseif id == 'availability' then
		if String.isEmpty(args.category) and String.isEmpty(args.tier) then return {} end
		return {
			Title{children = 'Type'},
			Cell{name = 'Category', children = {args.category}},
			Cell{name = 'Tier', children = {args.tier}},
		}
	elseif id == 'recipe' then
		if String.isEmpty(args.recipe) then return {} end
		return {
			Title{children = 'Components'},
			Center{children = {args.recipe}}
		}
	elseif id == 'maps' then return {}
	elseif id == 'info' then return {}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.append({},
		String.isNotEmpty(args.movespeed) and 'Movement Speed Items' or nil,
		String.isNotEmpty(args.category) and (args.category .. ' Items') or nil,
		String.isNotEmpty(args.active) and 'Items with Active Abilities' or nil,
		String.isNotEmpty(args.passive) and 'Items with Passive Abilities' or nil
	)
end

---@return string
function CustomItem:_getCostDisplay()
	return tostring(mw.html.create('div')
		:node(AutoInlineIcon.display{onlyicon = true, category = 'M', lookup = 'Souls'})
		:wikitext(' '):wikitext(self.args.itemcost))
end

---@param text string|number|nil
---@return Html
function CustomItem._costInnerDiv(text)
	return mw.html.create('div')
		:css('display', 'inline-block')
		:css('padding', '0px 3px')
		:css('border-radius', '4px')
		:wikitext(text)
end

---@param caller DeadlockItemInfobox
---@param base string?
---@return string?
function CustomItem._positiveConcatedArgsForBase(caller, base)
	if String.isEmpty(caller.args[base]) then return end
	---@cast base -nil
	local foundArgs = caller:getAllArgsForBase(caller.args, base)
	return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
end

---@param caller DeadlockItemInfobox
---@param base string?
---@return string?
function CustomItem._positivePercentDisplay(caller, base)
	if String.isEmpty(caller.args[base]) then
		return
	elseif not Logic.isNumeric(caller.args[base]) then
		error('"' .. base .. '" has to be numerical')
	end
	---@cast base -nil
	return '+ ' .. caller.args[base] .. '%'
end

---@param attributeCells {name: string, parameter: string?, funct: string?}[]
---@return table
function CustomItem:_getAttributeCells(attributeCells)
	return Array.map(attributeCells, function(attribute)
		local funct = attribute.funct or DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION
		local content = CustomItem[funct](self, attribute.parameter)
		if String.isEmpty(content) then return nil end
		return Cell{name = attribute.name, children = {content}}
	end)
end

---@param args table
function CustomItem:setLpdbData(args)
	local lpdbData = {
		type = 'item',
		name = args.name or self.pagename,
		image = args.image,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			cost = args.itemcost,
			category = args.category,
			removed = tostring(Logic.readBool(args.removed)),
			tier = tonumber(args.tier),
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('item_' .. (args.name or self.pagename), lpdbData)
end

return CustomItem
