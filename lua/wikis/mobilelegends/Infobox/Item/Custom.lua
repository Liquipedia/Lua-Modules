---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:CostDisplay')
local ItemIcon = require('Module:ItemIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class MobilelegendsItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION = '_positiveConcatedArgsForBase'
local ITEM_TYPE = {
	['regular'] = 'Regular',
	['footwear'] = 'Footwear',
	['advanced footwear'] = 'Advanced Footwear',
	['special'] = 'Special',
	['potion'] = 'Potion',
}
local SELL_RATE = {
	['regular'] = 0.6,
	['footwear'] = 0.6,
	['advanced footwear'] = 0.3,
}
local STATUS = {
	['available'] = 'Available',
	['replaced'] = 'Replaced',
	['removed'] = 'Removed',
}

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'header' then
		if String.isNotEmpty(args.itemname) then
			local iconImage = ItemIcon.display({}, args.itemname)
			table.insert(widgets, Center{children = {iconImage}})
		end
		return widgets
	elseif id == 'info' then
		return {
			Title{children = 'Item Information'},
			Cell{name = 'Cost', content = {caller:_getCostDisplay()}},
			Cell{name = 'Sell Value', content = {caller:_getSellValueDisplay()}},
			Cell{name = 'Category', content = caller:_getItemCategories(args)},
			Cell{name = 'Tier', content = {args.tier}},
			Cell{name = 'Type', content = {ITEM_TYPE[(args.type or ''):lower()]}},
			Cell{name = 'Status', content = {STATUS[(args.status or ''):lower()]}}
		}
	elseif id == 'attributes' then
		local attributeCells = {
			{name = 'HP', parameter = 'hp'},
			{name = 'HP Regen', parameter = 'hpregen'},
			{name = 'Mana', parameter = 'mana'},
			{name = 'Mana Regen', parameter = 'manaregen'},
			{name = 'Lifesteal', parameter = 'lifesteal', funct = '_positivePercentDisplay'},
			{name = 'Hybrid Lifesteal', parameter = 'hybridsteal', funct = '_positivePercentDisplay'},
			{name = 'Healing Effect', parameter = 'healeffect'},
			{name = 'Spell Vamp', parameter = 'spellvamp', funct = '_positivePercentDisplay'},
			{name = 'Physical Defense', parameter = 'physdefense'},
			{name = 'Magic Defense', parameter = 'magicdefense'},
			{name = 'Attack Speed', parameter = 'attackspeed', funct = '_positivePercentDisplay'},
			{name = 'Physical Attack', parameter = 'physatk'},
			{name = 'Magic Power', parameter = 'mp'},
			{name = 'Adaptive Attack', parameter = 'adaptiveatk'},
			{name = 'Physical Penetration', parameter = 'physpen'},
			{name = 'Magic Penetration', parameter = 'magicpen'},
			{name = 'Cooldown Reduction', parameter = 'cdreduction', funct = '_positivePercentDisplay'},
			{name = 'Critical Chance', parameter = 'critchance', funct = '_positivePercentDisplay'},
			{name = 'Critical Damage', parameter = 'critdmg'},
			{name = 'Movement Speed', parameter = 'movespeed'},
			{name = 'Slow Reduction', parameter = 'slowreduction'},
			{name = 'Unique Attribute', parameter = 'uniqueattr'},
		}
		widgets = caller:_getAttributeCells(attributeCells)
		if Table.isNotEmpty(widgets) then
			table.insert(widgets, 1, Title{children = 'Attributes'})
		end
		return widgets
	elseif id == 'ability' then
		if String.isEmpty(args.active) and String.isEmpty(args.passive) then
			return {}
		end
		Array.appendWith(widgets,
			Cell{name = 'Active', content = {args.active}},
			Cell{name = 'Passive', content = {args.passive, args.passive2}}
		)
	elseif id == 'recipe' then
		if String.isEmpty(args.recipe) then return {} end
		table.insert(widgets, Center{children = {args.recipe}})
	elseif Table.includes({'caption', 'availability', 'maps'}, id) then
		return {}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	local categories = {}
	for _, category in ipairs(self:_getItemCategories(args)) do
		table.insert(categories, category .. ' Items')
	end
	return categories
end

---@param args table
---@return string[]
function CustomItem:_getItemCategories(args)
	local categories = {}
	for _, category in Table.iter.pairsByPrefix(args, 'category', {requireIndex = false}) do
		table.insert(categories, category)
	end
	return categories
end

---@return string?
function CustomItem:_getCostDisplay()
	local itemCost = self.args.itemcost
	local recipeCost = Abbreviation.make{text = self.args.recipecost, title = 'Recipe cost'}

	if String.isNotEmpty(recipeCost) then
		return CostDisplay.display('gold', '15px', itemCost) .. ' (' .. recipeCost .. ')'
	end
	return CostDisplay.display('gold', '15px', itemCost)
end

---@return string?
function CustomItem:_getSellValueDisplay()
	local itemCost = tonumber(self.args.itemcost) or 0
	local sellRate = SELL_RATE[(self.args.type or ''):lower()] or 0
	local sellValue = math.floor(itemCost * sellRate)

	if sellRate == 0 then
		return 'Unsellable'
	end
	return CostDisplay.display('gold', '15px', sellValue)
end

---@param caller MobilelegendsItemInfobox
---@param base string?
---@return string?
function CustomItem._positiveConcatedArgsForBase(caller, base)
	if String.isEmpty(caller.args[base]) then return end
	---@cast base -nil
	local foundArgs = caller:getAllArgsForBase(caller.args, base)
	return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
end

---@param caller MobilelegendsItemInfobox
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
		return Cell{name = attribute.name, content = {content}}
	end)
end

---@param args table
function CustomItem:setLpdbData(args)
	local extradata = {
		itemcost = args.itemcost,
		recipecost = args.recipecost,
		category = self:_getItemCategories(args),
		tier = tonumber(args.tier),
		itemtype = args.type,
		status = args.status,
	}

	local lpdbData = {
		type = 'item',
		name = args.itemname or self.name,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata)
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('item_' .. (args.itemname or self.pagename), lpdbData)
end

return CustomItem
