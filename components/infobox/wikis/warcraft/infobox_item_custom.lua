---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local GameClock = require('Module:GameClock')
local Hotkey = require('Module:Hotkey')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Item = Lua.import('Module:Infobox/Item', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomItem = Class.new()

local CustomInjector = Class.new(Injector)

local SELL_FACTOR = 0.6
local MISCELLANEOUS = 'Miscellaneous'
local GOBLIN_MERCHANT = 'Goblin Merchant'
local PURCHASABLE = 'Purchasable'
local CLASSES = {
	p = 'Permanent',
	permanent = 'Permanent',
	c = 'Charged',
	charged = 'Charged',
	w = 'Power Up',
	['power up'] = 'Power Up',
	a = 'Artifact',
	artifact = 'Artifact',
	r = 'Purchasable',
	purchasable = 'Purchasable',
	g = 'Campaign',
	campaign = 'Campaign',
	m = MISCELLANEOUS,
	miscellaneous = MISCELLANEOUS,
}

local _args

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local customItem = Item(frame)
	_args = customItem.args

	_args.imagesize = 64
	if _args.icon and not _args.image then
		_args.image = 'Wc3BTN' .. _args.icon .. '.png'
	end
	local caption = Array.append({_args.caption},
		Logic.readBool(_args.noncombat) and 'Non-Combat Consumable' or nil,
		Logic.readBool(_args.artifact) and 'Artifact' or nil,
		Logic.readBool(_args.unique) and 'Unique' or nil
	)
	_args.caption = Table.isNotEmpty(caption) and table.concat(caption, '<br>') or nil
	_args.soldFrom = CustomItem._soldFrom(_args.soldfrom)

	customItem.createWidgetInjector = CustomItem.createWidgetInjector
	customItem.getWikiCategories = CustomItem.getWikiCategories
	customItem.setLpdbData = CustomItem.setLpdbData

	return customItem:createInfobox()
end

---@param soldFromInput string?
---@return {name: string, link: string}[]
function CustomItem._soldFrom(soldFromInput)
	local soldFromArgs = Json.parseIfTable(soldFromInput) or {}
	local soldFrom = {}
	for _, name, index in Table.iter.pairsByPrefix(soldFromArgs, 'name') do
		table.insert(soldFrom, {name = name, link = (soldFromArgs['link' .. index] or name):gsub(' ', '_')})
	end

	return soldFrom
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		_args.desc and Title{name = 'Description'} or nil,
		Center{content = {_args.desc}},
		_args.history and Title{name = 'Item History'} or nil,
		Center{content = {_args.history}}
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'info' then
		return {
			Title{name = 'Item Information'},
			Cell{name = 'Level', content = {_args.level}},
			Cell{name = 'Class', content = {CLASSES[(_args.class or ''):lower()] or _args.class}},
			Cell{name = 'Charges', content = {_args.charges}},
		}
	elseif id == 'availability' then
		return Array.append(widgets,
			Cell{name = 'Sold From', content = Array.map(_args.soldFrom, function(soldFrom)
				return '[[' .. soldFrom.link .. '|' .. soldFrom.name .. ']]' end)},
			Cell{name = 'Requirements', content = {_args.requires}},
			Cell{name = 'Cost', content = {CostDisplay.run{gold = _args.gold, lumber = _args.lumber}}},
			Cell{name = 'Sell value', content = {CostDisplay.run{
				gold = SELL_FACTOR * (tonumber(_args.gold) or 0),
				lumber = SELL_FACTOR * (tonumber(_args.lumber) or 0)
			}}},
			Cell{name = 'Purchase Hotkey', content = {_args.hotkey and Hotkey.hotkey(_args.hotkey) or nil}},
			Cell{name = 'Stock Max', content = {_args.stock}},
			Cell{name = 'Stock Start Delay', content = {_args.stockstart and (
				Abbreviation.make(_args.stockstart .. 's', 'First available at ' .. GameClock.run(_args.stockstart))
			) or nil}},
			Cell{name = Abbreviation.make('Stock Repl. Interval', 'Stock Replenish Interval'), content = {_args.stockreplenish}}
		)
	elseif id == 'ability' then
		return Array.append(widgets,
			Cell{name = 'Cast Time', content = {_args.cast}},
			Cell{name = 'Cooldown', content = {_args.cooldown}},
			Cell{name = 'Cooldown Group', content = {_args.cooldown and (_args.coolgroup or
				Abbreviation.make('Custom', 'This item has its own cooldown group.')
			) or nil}},
			Cell{name = 'Duration', content = {_args.duration}}
		)
	elseif Table.includes({'attributes', 'maps', 'recipe'}, id) then
		return {}
	end

	return widgets
end

---@return WidgetInjector
function CustomItem:createWidgetInjector()
	return CustomInjector()
end

---@param args table
function CustomItem:setLpdbData(args)
	local class = (CLASSES[(args.class or ''):lower()] or MISCELLANEOUS)

	local extradata = {
		level = args.level,
		gold = args.gold,
		lumber = args.lumber,
		cooldown = args.cooldown,
		stock = args.stock,
		stockstart = args.stockstart,
		stockreplenish = args.stockreplenish,
		requirement = args.requirement,
		purchasedfromgoblinshop = tostring(class == PURCHASABLE and String.contains(args.soldfrom, GOBLIN_MERCHANT)),
	}

	Array.forEach(args.soldFrom, function(soldFrom, index)
		extradata['soldfrom' .. index] = soldFrom.link
	end)

	local lpdbData = {
		name = self.name,
		type = 'item',
		image = args.image,
		information = class .. ' Items',
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('item_' .. lpdbData.name, lpdbData)
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	local categories = Array.map(args.soldFrom, function(soldFrom) return soldFrom.link .. ' Items' end)

	local class = (CLASSES[(args.class or ''):lower()] or MISCELLANEOUS) .. ' Items'
	table.insert(categories, class)
	table.insert(categories, args.level and ('Level ' .. args.level .. ' Items') or nil)

	return categories
end

return CustomItem
