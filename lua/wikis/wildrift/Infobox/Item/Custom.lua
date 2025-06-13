---
-- @Liquipedia
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WildriftItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local CATEGORY_DISPLAY = {
	finished = 'Upgraded [[Category:Upgraded Items]]',
	upgraded = 'Upgraded [[Category:Upgraded Items]]',
	['top-tier'] = 'Top-Tier [[Category:Top-Tier Items]]',
	advanced = 'Mid-Tier [[Category:Mid-Tier Items]]',
	['mid-tier'] = 'Mid-Tier [[Category:Mid-Tier Items]]',
	['mid tier'] = 'Mid-Tier [[Category:Mid-Tier Items]]',
	basic = 'Basic [[Category:Basic Items]]',
	boot = 'Boot [[Category:Boots]]',
	enchantment = 'Enchantment [[Category:Enchantments]]',
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
		if String.isNotEmpty(args.itemcost) then
			table.insert(widgets, Breakdown{
				children = caller:_getCostDisplay(),
				classes = {
					'infobox-header',
					'wiki-backgroundcolor-light',
					'infobox-header-2',
					'infobox-gold'
				}
			})
		end
		if String.isEmpty(args.itemname) then return widgets end
		local iconImage = Template.safeExpand(mw.getCurrentFrame(), 'ItemIcon', {string.lower(args.itemname)}) or ''
		if String.isNotEmpty(args.itemtext) then
			iconImage = iconImage .. '<br><i>' .. args.itemtext .. '</i>'
		end
		table.insert(widgets, Center{children = {iconImage}})
	elseif id == 'attributes' then
		if not CustomItem._hasAttributes(args) then return {} end

		if not (String.isEmpty(args.str) and String.isEmpty(args.agi) and String.isEmpty(args.int)) then
			table.insert(widgets, Breakdown{classes = {'infobox-center'}, children = {
				caller:_attributeIcons('str'),
				caller:_attributeIcons('agi'),
				caller:_attributeIcons('int'),
			}})
		end
		Array.appendWith(widgets,
			Cell{name = 'Health', content = {caller:_positiveConcatedArgsForBase('hp')}},
			Cell{name = 'Max Health', content = {caller:_positiveConcatedArgsForBase('maxhealth')}},
			Cell{name = 'Health Regen', content = {caller:_positiveConcatedArgsForBase('hpregen')}},
			Cell{name = 'Health Regen / Lifesteal Amp', content = {caller:_positivePercentDisplay('hpregenamp')}},
			Cell{name = 'Mana', content = {caller:_positiveConcatedArgsForBase('mana')}},
			Cell{name = 'Mana Regen', content = {caller:_positiveConcatedArgsForBase('manaregen')}},
			Cell{name = 'Mana Cost / Mana Loss Reduction', content = {caller:_manaLossDisplay()}},
			Cell{name = 'Mana Regen Amplification', content = {caller:_positivePercentDisplay('manaregenamp')}},
			Cell{name = 'Lifesteal', content = {caller:_positiveConcatedArgsForBase('lifesteal')}},
			Cell{name = 'Spell Lifesteal', content = {caller:_positiveConcatedArgsForBase('spellsteal')}},
			Cell{name = 'Spell Lifesteal Amplification', content = {caller:_positiveConcatedArgsForBase('spellstealamp')}},
			Cell{name = 'Armor', content = {caller:_positiveConcatedArgsForBase('armor')}},
			Cell{name = 'Evasion', content = {caller:_positivePercentDisplay('evasion')}},
			Cell{name = 'Magic Resistance', content = {caller:_positiveConcatedArgsForBase('magicresist')}},
			Cell{name = 'Status Resistance', content = {caller:_positivePercentDisplay('statusresist')}},
			Cell{name = 'Debuff Duration', content = {caller:_positiveConcatedArgsForBase('debuffamp')}},
			Cell{name = 'Spell Amplification', content = {caller:_positivePercentDisplay('spellamp')}},
			Cell{name = 'Bonus GPM', content = {caller:_positiveConcatedArgsForBase('bonusgpm')}},
			Cell{name = 'Turn Rate Speed', content = {caller:_positiveConcatedArgsForBase('turnrate')}},
			Cell{name = 'Projectile Speed', content = {caller:_positiveConcatedArgsForBase('projectilespeed')}},
			Cell{name = 'Attack Damage', content = {caller:_negativeConcatedArgsForBase('damagedown')}},
			Cell{name = 'Armor', content = {caller:_negativeConcatedArgsForBase('armordown')}},
			Cell{name = 'Attack Speed', content = {caller:_negativeConcatedArgsForBase('attackspeeddown')}},
			Cell{name = 'Max Mana', content = {caller:_negativeConcatedArgsForBase('maxmanadown')}},
			Cell{name = 'Base Attack Time', content = {caller:_negativeConcatedArgsForBase('batdown')}},
			Cell{name = 'Base Damage', content = {caller:_positiveConcatedArgsForBase('basedamage')}},
			Cell{name = 'Damage', content = {caller:_positiveConcatedArgsForBase('damage')}},
			Cell{name = 'Attack Speed', content = {caller:_positiveConcatedArgsForBase('attackspeed')}},
			Cell{name = 'Ability Power', content = {caller:_positiveConcatedArgsForBase('ap')}},
			Cell{name = 'Attack Damage', content = {caller:_positiveConcatedArgsForBase('ad')}},
			Cell{name = 'Cooldown Reduction', content = {caller:_positiveConcatedArgsForBase('cdreduction')}},
			Cell{name = 'Ability Haste', content = {caller:_positiveConcatedArgsForBase('haste')}},
			Cell{name = 'Critical Chance', content = {caller:_positiveConcatedArgsForBase('critchance')}},
			Cell{name = 'Attack Range', content = {caller:_positiveConcatedArgsForBase('attackrange')}},
			Cell{name = 'Cast Range', content = {caller:_positiveConcatedArgsForBase('castrange')}},
			Cell{name = 'Day Vision', content = {caller:_positiveConcatedArgsForBase('dayvision')}},
			Cell{name = 'Night Vision', content = {caller:_positiveConcatedArgsForBase('nightvision')}},
			Cell{name = 'Movement Speed', content = {caller:_movementSpeedDisplay()}},
			Cell{name = 'Limitations', content = {args.limits}}
		)
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
		if String.isEmpty(args.category) and String.isEmpty(args.shop) and String.isEmpty(args.drop) then
			return {}
		end
		return {
			Title{children = 'Item Tier'},
			Cell{name = 'Category', content = {caller:_categoryDisplay()}},
			Cell{name = 'Bought From', content = caller:_shopDisplay()},
			Cell{name = 'Dropped From', content = {args.drop}},
		}
	elseif id == 'maps' then
		if String.isEmpty(args.wr) and String.isEmpty(args.ha) then return {} end
		Array.appendWith(widgets,
			Cell{name = '[[Wild Rift (Map)|Wild Rift]]', content = {args.wr}},
			Cell{name = '[[Howling Abyss]]', content = {args.ha}}
		)
	elseif id == 'recipe' then
		if String.isEmpty(args.recipe) then return {} end
		table.insert(widgets, Center{children = {args.recipe}})
	elseif id == 'info' then return {}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.append({},
		String.isNotEmpty(args.str) and 'Strength Items' or nil,
		String.isNotEmpty(args.str) and 'Attribute Items' or nil,
		String.isNotEmpty(args.agi) and 'Agility Items' or nil,
		String.isNotEmpty(args.agi) and 'Attribute Items' or nil,
		String.isNotEmpty(args.int) and 'Intelligence Items' or nil,
		String.isNotEmpty(args.int) and 'Attribute Items' or nil,
		String.isNotEmpty(args.hp) and 'Health Items' or nil,
		String.isNotEmpty(args.mana) and 'Mana Pool Items' or nil,
		String.isNotEmpty(args.hpregen) and 'Health Regeneration Items' or nil,
		String.isNotEmpty(args.manaregen) and 'Mana Regeneration Items' or nil,
		String.isNotEmpty(args.armor) and 'Armor Bonus Items' or nil,
		String.isNotEmpty(args.evasion) and 'Evasion Items' or nil,
		String.isNotEmpty(args.magicresist) and 'Magic Resistance Items' or nil,
		String.isNotEmpty(args.damage) and 'Damage Items' or nil,
		String.isNotEmpty(args.active) and 'Items with Active Items' or nil,
		String.isNotEmpty(args.passive) and 'Items with Passive Items' or nil,
		(String.isNotEmpty(args.movespeed) or String.isNotEmpty(args.movespeedmult)) and 'Movement Speed Items' or nil,
		not self:_categoryDisplay() and 'Unknown Type' or nil
	)
end

---@param args table
---@return string?
function CustomItem.nameDisplay(args)
	return args.itemname
end

---@return string[]
function CustomItem:_getCostDisplay()
	local costs = self:getAllArgsForBase(self.args, 'itemcost')

	local innerDiv = mw.html.create('div')
		:css('display', 'inline-block')
		:css('padding', '0px 3px')
		:css('border-radius', '4px')
		:addClass('placement-darkgrey')
		:wikitext(table.concat(costs, '&nbsp;/&nbsp;'))
	local outerDiv = mw.html.create('div')
		:wikitext(Template.safeExpand(
				mw.getCurrentFrame(),
				'icons',
				{'gold', size = '21px'},
				''
			) .. ' ' .. tostring(innerDiv)
		)
	local display = tostring(outerDiv)

	if String.isNotEmpty(self.args.recipecost) then
		innerDiv = mw.html.create('div')
			:css('display', 'inline-block')
			:css('padding', '0px 3px')
			:css('border-radius', '4px')
			:addClass('placement-darkgrey')
			:wikitext('(' .. self.args.recipecost .. ')')
		outerDiv = mw.html.create('div')
			:css('padding-top', '3px')
			:wikitext(Template.safeExpand(
					mw.getCurrentFrame(),
					'icons',
					{'recipe', size = '21px'},
					''
				) .. ' ' .. tostring(innerDiv)
			)
		display = display .. tostring(outerDiv)
	end

	return {display}
end

---@param args table
---@return boolean
function CustomItem._hasAttributes(args)
	return not (
		String.isEmpty(args.str) and
		String.isEmpty(args.agi) and
		String.isEmpty(args.int) and
		String.isEmpty(args.hp) and
		String.isEmpty(args.mana) and
		String.isEmpty(args.hpregen) and
		String.isEmpty(args.hpregenamp) and
		String.isEmpty(args.manaregen) and
		String.isEmpty(args.armor) and
		String.isEmpty(args.evasion) and
		String.isEmpty(args.magicresist) and
		String.isEmpty(args.statusresist) and
		String.isEmpty(args.debuffamp) and
		String.isEmpty(args.spellamp) and
		String.isEmpty(args.basedamage) and
		String.isEmpty(args.ad) and
		String.isEmpty(args.attackrange) and
		String.isEmpty(args.attackspeed) and
		String.isEmpty(args.movespeed) and
		String.isEmpty(args.movespeedmult) and
		String.isEmpty(args.lifesteal) and
		String.isEmpty(args.spellsteal) and
		String.isEmpty(args.turnrate) and
		String.isEmpty(args.projectilespeed) and
		String.isEmpty(args.dayvision) and
		String.isEmpty(args.nightvision) and
		String.isEmpty(args.maxhealth) and
		String.isEmpty(args.bonusgpm) and
		String.isEmpty(args.damagedown) and
		String.isEmpty(args.armordown) and
		String.isEmpty(args.attackspeeddown) and
		String.isEmpty(args.maxmanadown) and
		String.isEmpty(args.batdown) and
		String.isEmpty(args.critchance) and
		String.isEmpty(args.cdreduction) and
		String.isEmpty(args.ap)
	)
end

---@param attributeType string
---@return string
function CustomItem:_attributeIcons(attributeType)
	self.args[attributeType] = self.args[attributeType] or 0
	local attributes = self:getAllArgsForBase(self.args, attributeType)
	return Template.safeExpand(mw.getCurrentFrame(), 'AttributeIcon', {attributeType}, '')
		.. '<br><b>+ ' .. table.concat(attributes, '/ ') .. '</b>'
end

---@param base string?
---@return string?
function CustomItem:_positiveConcatedArgsForBase(base)
	if String.isEmpty(self.args[base]) then return end
	---@cast base -nil
	local foundArgs = self:getAllArgsForBase(self.args, base)
	return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
end

---@param base string?
---@return string?
function CustomItem:_negativeConcatedArgsForBase(base)
	if String.isEmpty(self.args[base]) then return end
	---@cast base -nil
	local foundArgs = self:getAllArgsForBase(self.args, base)
	return '- ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
end

---@param base string?
---@return string?
function CustomItem:_positivePercentDisplay(base)
	if String.isEmpty(self.args[base]) then return end
	---@cast base -nil
	return '+ ' .. (tonumber(self.args[base]) * 100) .. '%'
end

---@return string?
function CustomItem:_manaLossDisplay()
	local display = Array.append({},
		Logic.isNumeric(self.args['mana loss']) and ((tonumber(self.args['mana loss']) + 100) .. '%') or nil,
		Logic.isNumeric(self.args.manaloss) and ((tonumber(self.args.manaloss) + 100) .. '%') or nil
	)
	if Table.isEmpty(display) then return end
	return '+ ' .. table.concat(display)
end

---@return string?
function CustomItem:_movementSpeedDisplay()
	local display = Array.append({},
		String.nilIfEmpty(self.args.movespeed),
		Logic.isNumeric(self.args.movespeedmult) and ((tonumber(self.args.movespeedmult) + 100) .. '%') or nil
	)
	if Table.isEmpty(display) then return end
	return '+ ' .. table.concat(display)
end

---@return string?
function CustomItem:_categoryDisplay()
	return CATEGORY_DISPLAY[string.lower(self.args.category or '')]
end

---@return string[]
function CustomItem:_shopDisplay()
	local contents = {}
	local index = 1
	self.args.shop1 = self.args.shop1 or self.args.shop
	while String.isNotEmpty(self.args['shop' .. index]) do
		local shop = Template.safeExpand(mw.getCurrentFrame(), 'Shop', {self.args['shop' .. index]})
		table.insert(contents, shop)
		index = index + 1
	end
	return contents
end

---@param args table
function CustomItem:setLpdbData(args)
	local lpdbData = {
		type = 'item',
		name = args.itemname or self.pagename,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			cost = args.itemcost,
			category = args.category,
			type = args.itemtype,
			removed = tostring(Logic.readBool(args.removed)),
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('item_' .. (args.itemname or self.pagename), lpdbData)
end

return CustomItem
