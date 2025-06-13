---
-- @Liquipedia
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

local Injector = Lua.import('Module:Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)

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

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item:setWidgetInjector(CustomInjector(item))

	local args = item.args

	args.imagesize = 64
	if args.icon and not args.image then
		args.image = 'Wc3BTN' .. args.icon .. '.png'
	end
	local caption = Array.append({args.caption},
		Logic.readBool(args.noncombat) and 'Non-Combat Consumable' or nil,
		Logic.readBool(args.artifact) and 'Artifact' or nil,
		Logic.readBool(args.unique) and 'Unique' or nil
	)
	args.caption = Table.isNotEmpty(caption) and table.concat(caption, '<br>') or nil
	args.soldFrom = CustomItem._soldFrom(args.soldfrom)

	return item:createInfobox()
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

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		return Array.append(
			args.desc and Title{children = 'Description'} or nil,
			Center{children = {args.desc}},
			args.history and Title{children = 'Item History'} or nil,
			Center{children = {args.history}}
		)
	elseif id == 'info' then
		return {
			Title{children = 'Item Information'},
			Cell{name = 'Level', content = {args.level}},
			Cell{name = 'Class', content = {CLASSES[(args.class or ''):lower()] or args.class}},
			Cell{name = 'Charges', content = {args.charges}},
		}
	elseif id == 'availability' then
		return Array.append(widgets,
			Cell{name = 'Sold From', content = Array.map(args.soldFrom, function(soldFrom)
				return '[[' .. soldFrom.link .. '|' .. soldFrom.name .. ']]' end)},
			Cell{name = 'Requirements', content = {args.requires}},
			Cell{name = 'Cost', content = {CostDisplay.run{gold = args.gold, lumber = args.lumber}}},
			Cell{name = 'Sell value', content = {CostDisplay.run{
				gold = SELL_FACTOR * (tonumber(args.gold) or 0),
				lumber = SELL_FACTOR * (tonumber(args.lumber) or 0)
			}}},
			Cell{name = 'Purchase Hotkey', content = {args.hotkey and Hotkey.hotkey{hotkey = args.hotkey} or nil}},
			Cell{name = 'Stock Max', content = {args.stock}},
			Cell{name = 'Stock Start Delay', content = {args.stockstart and (
				Abbreviation.make{text = args.stockstart .. 's', title = 'First available at ' .. GameClock.run(args.stockstart)}
			) or nil}},
			Cell{
				name = Abbreviation.make{text = 'Stock Repl. Interval',title = 'Stock Replenish Interval'},
				content = {args.stockreplenish}
			}
		)
	elseif id == 'ability' then
		return Array.append(widgets,
			Cell{name = 'Cast Time', content = {args.cast}},
			Cell{name = 'Cooldown', content = {args.cooldown}},
			Cell{name = 'Cooldown Group', content = {args.cooldown and (args.coolgroup or
				Abbreviation.make{text = 'Custom', title = 'This item has its own cooldown group.'}
			) or nil}},
			Cell{name = 'Duration', content = {args.duration}}
		)
	elseif Table.includes({'attributes', 'maps', 'recipe'}, id) then
		return {}
	end

	return widgets
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
		requirement = args.requires,
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
