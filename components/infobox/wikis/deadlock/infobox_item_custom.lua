---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DeadlockIcon = require('Module:DeadlockIcon')
local ItemIcon = require('Module:ItemIcon')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Breakdown = Widgets.Breakdown

---@class DeadlockItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local CATEGORY_DISPLAY = {
	['weapon'] = 'Weapon [[Category:Weapon Items]]',
	['vitality'] = 'Vitality [[Category:Vitality Items]]',
	['spirit'] = 'Spirit [[Category:Spirit Items]]',
}

local DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION = '_positiveConcatedArgsForBase'

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
		if String.isNotEmpty(args.itemcost) then
			table.insert(widgets, Breakdown{
				content = caller:_getCostDisplay(),
				classes = {
					'infobox-header',
					'wiki-backgroundcolor-light',
					'infobox-header-2',
					'infobox-gold'
				}
			})
		end
		if String.isNotEmpty(args.itemname) then
			local iconImage = ItemIcon.display({}, args.itemname)
			if String.isNotEmpty(args.itemtext) then
				iconImage = iconImage .. '<br><i>' .. args.itemtext .. '</i>'
			end
			table.insert(widgets, Center{content = {iconImage}})
		end
		return widgets
	elseif id == 'attributes' then
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
			{name = 'Stamina Recovery', parameter = 'staminarecov', funct = '_positivePercentDisplay'},
			{name = 'Slide Distance', parameter = 'slidedistance', funct = '_positivePercentDisplay'},
			{name = 'Spirit Power', parameter = 'spiritpower'},
			{name = 'Spirit Resist', parameter = 'spiritresist'},
			{name = 'Spirit Shield Health', parameter = 'spiritshield'},
			{name = 'Spirit Lifesteal', parameter = 'spiritlifesteal', funct = '_positivePercentDisplay'},
			{name = 'Cooldown Reduction', parameter = 'cdreduction', funct = '_positivePercentDisplay'},
			{name = 'Movement Speed', parameter = 'movespeed'},
			{name = 'Ability Range', parameter = 'abilityrange', funct = '_positivePercentDisplay'},
			{name = 'Ability Duration', parameter = 'abilityduration', funct = '_positivePercentDisplay'},
			{name = 'Melee Range', parameter = 'meleerange', funct = '_positivePercentDisplay'},
			{name = 'Melee Damage', parameter = 'meleedmg', funct = '_positivePercentDisplay'}
		}
		widgets = caller:_getAttributeCells(attributeCells)
		if not Table.isEmpty(widgets) then
			table.insert(widgets, 1, Title{name = 'Attributes'})
		end
		return widgets
	elseif id == 'ability' then
		if String.isEmpty(args.use) and String.isEmpty(args.active) and String.isEmpty(args.passive) then
			return {}
		end
		Array.appendWith(widgets,
			Cell{name = 'Use', content = {args.use}},
			Cell{name = 'Active', content = {args.active}},
			Cell{name = 'Passive', content = {args.passive, args.passive2}}
		)
	elseif id == 'availability' then
		if String.isEmpty(args.category) and String.isEmpty(args.drop) then return {} end
		return {
			Title{name = 'Item Tier'},
			Cell{name = 'Category', content = {caller:_categoryDisplay()}},
			Cell{name = 'Dropped From', content = {args.drop}},
		}
	elseif id == 'recipe' then
		if String.isEmpty(args.recipe) then return {} end
		table.insert(widgets, Center{content = {args.recipe}})
	elseif id == 'maps' then return {}
	elseif id == 'info' then return {}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	local categories = {}
	if String.isNotEmpty(args.str) or String.isNotEmpty(args.agi) or String.isNotEmpty(args.int) then
		table.insert(categories, 'Attribute Items')
	end

	if String.isNotEmpty(args.movespeed) or String.isNotEmpty(args.movespeedmult) then
		table.insert(categories, 'Movement Speed Items')
	end

	local possibleCategories = {
		['Items with Active Abilities'] = 'active',
		['Items with Passive Abilities'] = 'passive',
	}
	for category, requiredArg in pairs(possibleCategories) do
		if String.isNotEmpty(args[requiredArg]) then
			table.insert(categories, category)
		end
	end
	return categories
end

---@param args table
---@return string?
function CustomItem.nameDisplay(args)
	return args.itemname
end

---@return string[]
function CustomItem:_getCostDisplay()
	local costs = self:getAllArgsForBase(self.args, 'itemcost')

	local innerDiv = CustomItem._costInnerDiv(table.concat(costs, '&nbsp;/&nbsp;'))
	local outerDiv = mw.html.create('div')
		:wikitext(DeadlockIcon.display({}, 'souls', '14') .. ' ' .. tostring(innerDiv))
	local display = tostring(outerDiv)

	if String.isNotEmpty(self.args.recipecost) then
		innerDiv = CustomItem._costInnerDiv('(' .. self.args.recipecost .. ')')
		outerDiv = mw.html.create('div')
			:css('padding-top', '3px')
			:wikitext(DeadlockIcon.display({}, 'recipe', '21') .. ' ' .. tostring(innerDiv))
		display = display .. tostring(outerDiv)
	end

	return {display}
end

---@param text string|number|nil
---@return Html
function CustomItem._costInnerDiv(text)
	return mw.html.create('div')
		:css('display', 'inline-block')
		:css('padding', '0px 3px')
		:css('border-radius', '4px')
		:addClass('placement-darkgrey')
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

---@return string?
function CustomItem:_categoryDisplay()
	return CATEGORY_DISPLAY[string.lower(self.args.category or '')]
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

return CustomItem
