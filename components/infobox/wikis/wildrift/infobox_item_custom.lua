---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Item = Lua.import('Module:Infobox/Item', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomItem = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _frame
local _categories = {}

local _CATEGORY_DISPLAY = {
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

function CustomItem.run(frame)
	local item = Item(frame)
	_args = item.args
	_frame = frame

	item.nameDisplay = CustomItem.nameDisplay
	item.getWikiCategories = CustomItem.getWikiCategories
	--item.setLpdbData = CustomItem.setLpdbData--to be added later
	item.createWidgetInjector = CustomItem.createWidgetInjector

	return item:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'header' then
		if not String.isEmpty(_args.itemcost) then
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
		if not String.isEmpty(_args.itemname) then
			local iconImage = Template.safeExpand(_frame, 'ItemIcon', {string.lower(_args.itemname)}, '')
			if not String.isEmpty(_args.itemtext) then
				iconImage = iconImage .. '<br><i>' .. _args.itemtext .. '</i>'
			end
			table.insert(widgets, Center{content = {iconImage}})
		end
		return widgets
	elseif id == 'attributes' then
		if CustomItem._hasAttributes() then
			if not (String.isEmpty(_args.str) and
				String.isEmpty(_args.agi) and
				String.isEmpty(_args.int))
			then
				table.insert(widgets, Breakdown{classes = {'infobox-center'}, content = {
					CustomItem._attributeIcons('str'),
					CustomItem._attributeIcons('agi'),
					CustomItem._attributeIcons('int'),
				}})
			end
			table.insert(widgets, Cell{name = 'Health', content = {
				CustomItem._positiveConcatedArgsForBase('hp')
			}})
			table.insert(widgets, Cell{name = 'Max Health', content = {
				CustomItem._positiveConcatedArgsForBase('maxhealth')
			}})
			table.insert(widgets, Cell{name = 'Health Regen', content = {
				CustomItem._positiveConcatedArgsForBase('hpregen')
			}})
			table.insert(widgets, Cell{name = 'Health Regen / Lifesteal Amp', content = {
				CustomItem._positivePercentDisplay('hpregenamp')
			}})
			table.insert(widgets, Cell{name = 'Mana', content = {
				CustomItem._positiveConcatedArgsForBase('mana')
			}})
			table.insert(widgets, Cell{name = 'Mana Regen', content = {
				CustomItem._positiveConcatedArgsForBase('manaregen')
			}})
			table.insert(widgets, Cell{name = 'Mana Cost / Mana Loss Reduction', content = {
				CustomItem._manaLossDisplay()
			}})
			table.insert(widgets, Cell{name = 'Mana Regen Amplification', content = {
				CustomItem._positivePercentDisplay('manaregenamp')
			}})
			table.insert(widgets, Cell{name = 'Lifesteal', content = {
				CustomItem._positiveConcatedArgsForBase('lifesteal')
			}})
			table.insert(widgets, Cell{name = 'Spell Lifesteal', content = {
				CustomItem._positiveConcatedArgsForBase('spellsteal')
			}})
			table.insert(widgets, Cell{name = 'Spell Lifesteal Amplification', content = {
				CustomItem._positiveConcatedArgsForBase('spellstealamp')
			}})
			table.insert(widgets, Cell{name = 'Armor', content = {
				CustomItem._positiveConcatedArgsForBase('armor')
			}})
			table.insert(widgets, Cell{name = 'Evasion', content = {
				CustomItem._positivePercentDisplay('evasion')
			}})
			table.insert(widgets, Cell{name = 'Magic Resistance', content = {
				CustomItem._positiveConcatedArgsForBase('magicresist')
			}})
			table.insert(widgets, Cell{name = 'Status Resistance', content = {
				CustomItem._positivePercentDisplay('statusresist')
			}})
			table.insert(widgets, Cell{name = 'Debuff Duration', content = {
				CustomItem._positiveConcatedArgsForBase('debuffamp')
			}})
			table.insert(widgets, Cell{name = 'Spell Amplification', content = {
				CustomItem._positivePercentDisplay('spellamp')
			}})
			table.insert(widgets, Cell{name = 'Bonus GPM', content = {
				CustomItem._positiveConcatedArgsForBase('bonusgpm')
			}})
			table.insert(widgets, Cell{name = 'Turn Rate Speed', content = {
				CustomItem._positiveConcatedArgsForBase('turnrate')
			}})
			table.insert(widgets, Cell{name = 'Projectile Speed', content = {
				CustomItem._positiveConcatedArgsForBase('projectilespeed')
			}})
			table.insert(widgets, Cell{name = 'Attack Damage', content = {
				CustomItem._negativeConcatedArgsForBase('damagedown')
			}})
			table.insert(widgets, Cell{name = 'Armor', content = {
				CustomItem._negativeConcatedArgsForBase('armordown')
			}})
			table.insert(widgets, Cell{name = 'Attack Speed', content = {
				CustomItem._negativeConcatedArgsForBase('attackspeeddown')
			}})
			table.insert(widgets, Cell{name = 'Max Mana', content = {
				CustomItem._negativeConcatedArgsForBase('maxmanadown')
			}})
			table.insert(widgets, Cell{name = 'Base Attack Time', content = {
				CustomItem._negativeConcatedArgsForBase('batdown')
			}})
			table.insert(widgets, Cell{name = 'Base Damage', content = {
				CustomItem._positiveConcatedArgsForBase('basedamage')
			}})
			table.insert(widgets, Cell{name = 'Damage', content = {
				CustomItem._positiveConcatedArgsForBase('damage')
			}})
			table.insert(widgets, Cell{name = 'Attack Speed', content = {
				CustomItem._positiveConcatedArgsForBase('attackspeed')
			}})
			table.insert(widgets, Cell{name = 'Ability Power', content = {
				CustomItem._positiveConcatedArgsForBase('ap')
			}})
			table.insert(widgets, Cell{name = 'Attack Damage', content = {
				CustomItem._positiveConcatedArgsForBase('ad')
			}})
			table.insert(widgets, Cell{name = 'Ability Haste', content = {
				CustomItem._positiveConcatedArgsForBase('cdreduction')
			}})
			table.insert(widgets, Cell{name = 'Ability Haste', content = {
				CustomItem._positiveConcatedArgsForBase('haste')
			}})
			table.insert(widgets, Cell{name = 'Critical Chance', content = {
				CustomItem._positiveConcatedArgsForBase('critchance')
			}})
			table.insert(widgets, Cell{name = 'Attack Range', content = {
				CustomItem._positiveConcatedArgsForBase('attackrange')
			}})
			table.insert(widgets, Cell{name = 'Cast Range', content = {
				CustomItem._positiveConcatedArgsForBase('castrange')
			}})
			table.insert(widgets, Cell{name = 'Day Vision', content = {
				CustomItem._positiveConcatedArgsForBase('dayvision')
			}})
			table.insert(widgets, Cell{name = 'Night Vision', content = {
				CustomItem._positiveConcatedArgsForBase('nightvision')
			}})
			table.insert(widgets, Cell{name = 'Movement Speed', content = {
				CustomItem._movementSpeedDisplay()
			}})
			table.insert(widgets, Cell{name = 'Limitations', content = {
				_args.limits
			}})
		else return {} end
	elseif id == 'ability' then
		if not (String.isEmpty(_args.use) and
			String.isEmpty(_args.active) and
			String.isEmpty(_args.passive))
		then
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
		else return {} end
	elseif id == 'availability' then
		if not (String.isEmpty(_args.category) and
			String.isEmpty(_args.shop) and
			String.isEmpty(_args.drop))
		then
			return {
				Title{name = 'Item Tier'},
				Cell{name = 'Category', content = {CustomItem._categoryDisplay()}},
				Cell{name = 'Bought From', content = CustomItem._shopDisplay()},
				Cell{name = 'Dropped From', content = {_args.drop}},
			}
		else return {} end
	elseif id == 'maps' then
		if not (String.isEmpty(_args.wr) and
			String.isEmpty(_args.ha))
		then
			table.insert(widgets, Cell{name = '[[Wild Rift (Map)|Wild Rift]]', content = {_args.wr}})
			table.insert(widgets, Cell{name = '[[Howling Abyss]]', content = {_args.ha}})
		else return {} end
	elseif id == 'recipe' then
		if not String.isEmpty(_args.recipe) then
			table.insert(widgets, Center{content = {_args.recipe}})
		else return {} end
	elseif id == 'info' then return {}
	end

	return widgets
end

function CustomItem:createWidgetInjector()
	return CustomInjector()
end

function CustomItem.getWikiCategories()
	if Namespace.isMain() then
		if not String.isEmpty(_args.str) then
			table.insert(_categories, 'Strength Items')
			table.insert(_categories, 'Attribute Items')
		end
		if not String.isEmpty(_args.agi) then
			table.insert(_categories, 'Agility Items')
			table.insert(_categories, 'Attribute Items')
		end
		if not String.isEmpty(_args.int) then
			table.insert(_categories, 'Intelligence Items')
			table.insert(_categories, 'Attribute Items')
		end
		if not String.isEmpty(_args.hp) then
			table.insert(_categories, 'Health Items')
		end
		if not String.isEmpty(_args.mana) then
			table.insert(_categories, 'Mana Pool Items')
		end
		if not String.isEmpty(_args.hpregen) then
			table.insert(_categories, 'Health Regeneration Items')
		end
		if not String.isEmpty(_args.manaregen) then
			table.insert(_categories, 'Mana Regeneration Items')
		end
		if not String.isEmpty(_args.armor) then
			table.insert(_categories, 'Armor Bonus Items')
		end
		if not String.isEmpty(_args.evasion) then
			table.insert(_categories, 'Evasion Items')
		end
		if not String.isEmpty(_args.magicresist) then
			table.insert(_categories, 'Magic Resistance Items')
		end
		if not String.isEmpty(_args.damage) then
			table.insert(_categories, 'Damage Items')
		end
		if not String.isEmpty(_args.active) then
			table.insert(_categories, 'Items with Active Abilities')
		end
		if not String.isEmpty(_args.passive) then
			table.insert(_categories, 'Items with Passive Abilities')
		end
		if not (String.isEmpty(_args.movespeed) and String.isEmpty(_args.movespeedmult)) then
			table.insert(_categories, 'Movement Speed Items')
		end
	end

	return _categories

end

function CustomItem.nameDisplay()
	return _args.itemname
end

function CustomItem._getCostDisplay()
	local costs = Item:getAllArgsForBase(_args, 'itemcost')

	local innerDiv = mw.html.create('div')
		:css('display', 'inline-block')
		:css('padding', '0px 3px')
		:css('border-radius', '4px')
		:addClass('placement-darkgrey')
		:wikitext(table.concat(costs, '&nbsp;/&nbsp;'))
	local outerDiv = mw.html.create('div')
		:wikitext(Template.safeExpand(
				_frame,
				'icons',
				{'gold', size = '21px'},
				''
			) .. ' ' .. tostring(innerDiv)
		)
	local display = tostring(outerDiv)

	if not String.isEmpty(_args.recipecost) then
		innerDiv = mw.html.create('div')
			:css('display', 'inline-block')
			:css('padding', '0px 3px')
			:css('border-radius', '4px')
			:addClass('placement-darkgrey')
			:wikitext('(' .. _args.recipecost .. ')')
		outerDiv = mw.html.create('div')
			:css('padding-top', '3px')
			:wikitext(Template.safeExpand(
					_frame,
					'icons',
					{'recipe', size = '21px'},
					''
				) .. ' ' .. tostring(innerDiv)
			)
		display = display .. tostring(outerDiv)
	end

	return {display}
end

function CustomItem._hasAttributes()
	return not (
		String.isEmpty(_args.str) and
		String.isEmpty(_args.agi) and
		String.isEmpty(_args.int) and
		String.isEmpty(_args.hp) and
		String.isEmpty(_args.mana) and
		String.isEmpty(_args.hpregen) and
		String.isEmpty(_args.hpregenamp) and
		String.isEmpty(_args.manaregen) and
		String.isEmpty(_args.armor) and
		String.isEmpty(_args.evasion) and
		String.isEmpty(_args.magicresist) and
		String.isEmpty(_args.statusresist) and
		String.isEmpty(_args.debuffamp) and
		String.isEmpty(_args.spellamp) and
		String.isEmpty(_args.basedamage) and
		String.isEmpty(_args.ad) and
		String.isEmpty(_args.attackrange) and
		String.isEmpty(_args.attackspeed) and
		String.isEmpty(_args.movespeed) and
		String.isEmpty(_args.movespeedmult) and
		String.isEmpty(_args.lifesteal) and
		String.isEmpty(_args.spellsteal) and
		String.isEmpty(_args.turnrate) and
		String.isEmpty(_args.projectilespeed) and
		String.isEmpty(_args.dayvision) and
		String.isEmpty(_args.nightvision) and
		String.isEmpty(_args.maxhealth) and
		String.isEmpty(_args.bonusgpm) and
		String.isEmpty(_args.damagedown) and
		String.isEmpty(_args.armordown) and
		String.isEmpty(_args.attackspeeddown) and
		String.isEmpty(_args.maxmanadown) and
		String.isEmpty(_args.batdown) and
		String.isEmpty(_args.critchance) and
		String.isEmpty(_args.cdreduction) and
		String.isEmpty(_args.ap)
	)
end

function CustomItem._attributeIcons(attributeType)
	_args[attributeType] = _args[attributeType] or 0
	local attributes = Item:getAllArgsForBase(_args, attributeType)
	return Template.safeExpand(_frame, 'AttributeIcon', {attributeType}, '')
		.. '<br><b>+ ' .. table.concat(attributes, '/ ') .. '</b>'
end

function CustomItem._positiveConcatedArgsForBase(base)
	if not String.isEmpty(_args[base]) then
		local foundArgs = Item:getAllArgsForBase(_args, base)
		return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
	end
end

function CustomItem._negativeConcatedArgsForBase(base)
	if not String.isEmpty(_args[base]) then
		local foundArgs = Item:getAllArgsForBase(_args, base)
		return '- ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
	end
end

function CustomItem._positivePercentDisplay(base)
mw.logObject(base)
	if not String.isEmpty(_args[base]) then
		local number = tonumber(_args[base])
		number = number * 100
		return '+ ' .. number .. '%'
	end
end

function CustomItem._manaLossDisplay()
	local display = ''
	if not String.isEmpty(_args['mana loss']) then
		display = (tonumber(_args['mana loss']) + 100) .. '%'
	end
	if not String.isEmpty(_args.manaloss) then
		display = display .. (tonumber(_args.manaloss) + 100) .. '%'
	end
	if display ~= '' then
		return '+ ' .. display
	end
end

function CustomItem._movementSpeedDisplay()
	local display = ''
	if not String.isEmpty(_args.movespeed) then
		display = _args.movespeed
	end
	if not String.isEmpty(_args.movespeedmult) then
		display = display .. (tonumber(_args.movespeedmult) + 100) .. '%'
	end
	if display ~= '' then
		return '+ ' .. display
	end
end

function CustomItem._categoryDisplay()
	local display = _CATEGORY_DISPLAY[string.lower(_args.category or '')]
	if display then
		return display
	else
		table.insert(_categories, 'Unknown Type')
	end
end

function CustomItem._shopDisplay()
	local contents = {}
	local index = 1
	_args.shop1 = _args.shop1 or _args.shop
	while not String.isEmpty(_args['shop' .. index]) do
		local shop = Template.safeExpand(_frame, 'Shop', {_args['shop' .. index]})
		table.insert(contents, shop)
		index = index + 1
	end
	return contents
end

return CustomItem
