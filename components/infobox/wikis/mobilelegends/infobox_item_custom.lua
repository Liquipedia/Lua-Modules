---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Icon = require('Module:Icon')
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

local CustomItem = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _categories = {}

local _CATEGORY_DISPLAY = {
	['tier 1'] = 'Tier 1 [[Category:Tier 1 Items]]',
	['tier 2'] = 'Tier 2 [[Category:Tier 2 Items]]',
	['tier 3'] = 'Tier 3 [[Category:Tier 3 Items]]',
	basic = 'Basic [[Category:Basic Items]]',
	boot = 'Boot [[Category:Boots]]',
	enchantment = 'Enchantment [[Category:Enchantments]]',
}

local _DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION = '_positiveConcatedArgsForBase'

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = Item(frame)
	_args = item.args

	item.nameDisplay = CustomItem.nameDisplay
	item.getWikiCategories = CustomItem.getWikiCategories
	item.createWidgetInjector = CustomItem.createWidgetInjector

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'header' then
		if String.isNotEmpty(_args.itemcost) then
			table.insert(
				widgets,
				Breakdown{
					content = CustomItem._getCostDisplay(),
					classes = {
						'infobox-header',
						'wiki-backgroundcolor-light',
						'infobox-header-2',
						'infobox-gold'
					}
				}
			)
		end
		if String.isNotEmpty(_args.itemname) then
			local iconImage = ItemIcon.display({}, _args.itemname)
			if String.isNotEmpty(_args.itemtext) then
				iconImage = iconImage .. '<br><i>' .. _args.itemtext .. '</i>'
			end
			table.insert(widgets, Center{content = {iconImage}})
		end
		return widgets
	elseif id == 'attributes' then
		local attributeCells = {
			{name = 'Health', parameter = 'hp'},
			{name = 'Max Health', parameter = 'maxhealth'},
			{name = 'Health Regen', parameter = 'hpregen'},
			{name = 'Mana', parameter = 'mana'},
			{name = 'Mana Regen', parameter = 'manaregen'},
			{name = 'Mana Loss', parameter = 'manaloss', funct = '_positivePercentDisplay'},
			{name = 'Lifesteal', parameter = 'lifesteal'},
			{name = 'Physical Lifesteal', parameter = 'physsteal'},
			{name = 'Magical Lifesteal', parameter = 'magicsteal'},
			{name = 'Armor', parameter = 'armor'},
			{name = 'Evasion', parameter = 'evasion', funct = '_positivePercentDisplay'},
			{name = 'Magic Resistance', parameter = 'magicresist'},
			{name = 'Status Resistance', parameter = 'statusresist', funct = '_positivePercentDisplay'},
			{name = 'Attack Speed', parameter = 'attackspeed'},
			{name = 'Cooldown Reduction', parameter = 'cdreduction'},
			{name = 'Magic Power', parameter = 'mp'},
			{name = 'Attack Damage', parameter = 'ad'},
			{name = 'Physical Attack', parameter = 'physatk'},
			{name = 'Physical Penetration', parameter = 'physpen'},
			{name = 'Magical Penetration', parameter = 'magicpen'},
			{name = 'Cooldown Reduction', parameter = 'cdreduction'},
			{name = 'Critical Chance', parameter = 'critchance'},
			{name = 'Movement Speed', funct = '_movementSpeedDisplay'},
		}
		widgets = CustomItem._getAttributeCells(attributeCells)
		if not Table.isEmpty(widgets) then
			table.insert(widgets, 1, Title{name = 'Attributes'})
		end
		return widgets
	elseif id == 'ability' then
		if
			String.isEmpty(_args.use) and
			String.isEmpty(_args.active) and
			String.isEmpty(_args.passive)
		then
			return {}
		end
		table.insert(widgets, Cell{name = 'Use', content = {
			_args.use
		}})
		table.insert(widgets, Cell{name = 'Active', content = {
			_args.active
		}})
		table.insert(widgets, Cell{name = 'Passive', content = {
			_args.passive,
			_args.passive2
		}})
	elseif id == 'availability' then
		if
			String.isEmpty(_args.category) and
			String.isEmpty(_args.drop)
		then
			return {}
		end
		return {
			Title{name = 'Item Tier'},
			Cell{name = 'Category', content = {CustomItem._categoryDisplay()}},
			Cell{name = 'Dropped From', content = {_args.drop}},
		}
	elseif id == 'maps' then
		if String.isEmpty(_args.sr) and String.isEmpty(_args.ha) then
			return {}
		else
			table.insert(widgets, Cell{name = '[[Summoner\'s Rift]]', content = {_args.sr}})
			table.insert(widgets, Cell{name = '[[Howling Abyss]]', content = {_args.ha}})
		end
	elseif id == 'recipe' then
		if String.isEmpty(_args.recipe) then
			return {}
		else
			table.insert(widgets, Center{content = {_args.recipe}})
		end
	elseif id == 'info' then return {}
	end

	return widgets
end

---@return WidgetInjector
function CustomItem:createWidgetInjector()
	return CustomInjector()
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if Namespace.isMain() then
		if
			String.isNotEmpty(args.str) or
			String.isNotEmpty(args.agi) or
			String.isNotEmpty(args.int)
		then
			table.insert(_categories, 'Attribute Items')
		end

		if String.isNotEmpty(args.movespeed) or String.isNotEmpty(args.movespeedmult) then
			table.insert(_categories, 'Movement Speed Items')
		end

		local possibleCategories = {
			['Strength Items'] = 'str',
			['Agility Items'] = 'agi',
			['Intelligence Items'] = 'int',
			['Health Items'] = 'hp',
			['Mana Pool Items'] = 'mana',
			['Health Regeneration Items'] = 'hpregen',
			['Mana Regeneration Items'] = 'manaregen',
			['Armor Bonus Items'] = 'armor',
			['Evasion Items'] = 'evasion',
			['Magic Resistance Items'] = 'magicresist',
			['Damage Items'] = 'damage',
			['Items with Active Abilities'] = 'active',
			['Items with Passive Abilities'] = 'passive',
		}
		for category, requiredArg in pairs(possibleCategories) do
			if String.isNotEmpty(args[requiredArg]) then
				table.insert(_categories, category)
			end
		end

		return _categories
	end

	return {}
end

---@param args table
---@return string?
function CustomItem.nameDisplay(args)
	return args.itemname
end

---@return string[]
function CustomItem._getCostDisplay()
	local costs = Item:getAllArgsForBase(_args, 'itemcost')

	local innerDiv = CustomItem._costInnerDiv(table.concat(costs, '&nbsp;/&nbsp;'))
	local outerDiv = mw.html.create('div')
		:wikitext(Icon.display({}, 'gold', '21') .. ' ' .. tostring(innerDiv))
	local display = tostring(outerDiv)

	if String.isNotEmpty(_args.recipecost) then
		innerDiv = CustomItem._costInnerDiv('(' .. _args.recipecost .. ')')
		outerDiv = mw.html.create('div')
			:css('padding-top', '3px')
			:wikitext(Icon.display({}, 'recipe', '21') .. ' ' .. tostring(innerDiv))
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

---@param base string?
---@return string?
function CustomItem._positiveConcatedArgsForBase(base)
	if String.isNotEmpty(_args[base]) then
		---@cast base -nil
		local foundArgs = Item:getAllArgsForBase(_args, base)
		return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
	end
end

---@param base string?
---@return string?
function CustomItem._positivePercentDisplay(base)
	if String.isNotEmpty(_args[base]) then
		local number = tonumber(_args[base])
		if number == nil then
			error('"' .. base .. '" has to be numerical')
		end
		number = number * 100
		return '+ ' .. number .. '%'
	end
end

---@return string?
function CustomItem._movementSpeedDisplay()
	local display
	if String.isNotEmpty(_args.movespeed) then
		display = _args.movespeed
	elseif Logic.isNumeric(_args.movespeedmult) then
		display = (tonumber(_args.movespeedmult) + 100) .. '%'
	end
	if String.isNotEmpty(display) then
		return '+ ' .. display
	end
end

---@return string?
function CustomItem._categoryDisplay()
	local display = _CATEGORY_DISPLAY[string.lower(_args.category or '')]
	if display then
		return display
	else
		table.insert(_categories, 'Unknown Type')
	end
end

---@param attributeCells {name: string, parameter: string?, funct: string?}[]
---@return table
function CustomItem._getAttributeCells(attributeCells)
	local widgets = {}
	for _, attribute in ipairs(attributeCells) do
		local funct = attribute.funct or _DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION
		local content = CustomItem[funct](attribute.parameter)
		if String.isNotEmpty(content) then
			table.insert(widgets, Cell{name = attribute.name, content = {
				CustomItem[funct](attribute.parameter)
			}})
		end
	end

	return widgets
end

return CustomItem
