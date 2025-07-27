---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Image = require('Module:Widget/Image/Icon/Image')

local CRAFT_DATA = {
	common = {cost = '40 (Gold: 400)', value = '5 (Gold: 50)'},
	rare = {cost = '100 (Gold: 800)', value = '20 (Gold: 100)'},
	epic = {cost = '400 (Gold: 1600)', value = '100 (Gold: 400)'},
	legendary = {cost = '1600 (Gold: 3200)', value = '400 (Gold: 1600)'},
}

---@class HearthstoneUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class HearthstoneUnitInfoboxWidgetInjector: WidgetInjector
---@field caller HearthstoneUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Card'
	unit:setWidgetInjector(CustomInjector(unit))

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local hasAttributes = Logic.isNotEmpty(args.cost) or Logic.isNotEmpty(args.attack) or Logic.isNotEmpty(args.hp)

		---@param input string?
		---@return Widget?
		local makePatch = function(input)
			if not input then return end
			return Link{
				link = 'Patch ' .. input,
				children = {input},
			}
		end

		---@param image string
		---@param link string
		---@param value string?
		---@return Widget
		local makeAttribute = function(image, link, value)
			-- returning Fragment is needed to have placeholders where necessary
			if not value then return HtmlWidgets.Fragment{} end
			return HtmlWidgets.Fragment{children = {
				Image{size = 'x32px', alignment = 'text-top', link = link, imageLight = image},
				HtmlWidgets.Br{},
				value,
			}}
		end

		---@return Widget?
		local makeCraftable = function()
			if Logic.readBoolOrNil(args.craftable) == false or string.lower(args.set or '') ~= 'expert' then
				return
			end
			local craftData = CRAFT_DATA[args.rarity]
			if not craftData then return end
			return {
				Cell{name = 'Crafting Cost', children = {craftData.cost}},
				Cell{name = 'Disenchant Value', children = {craftData.value}},
			}
		end

		return WidgetUtil.collect(
			Cell{name = 'Rarity', children = {args.rarity}, options = {makeLink = true}},
			Cell{name = 'Set', children = {args.set}, options = {makeLink = true}},
			Cell{name = 'Summoned by', children = {args.summonedby}, options = {makeLink = true}},
			Cell{name = 'Chosen from', children = {args.chosenfrom}, options = {makeLink = true}},
			makeCraftable(),
			Cell{name = 'Introduced', children = {makePatch(args.startversion)}},
			Cell{name = 'Removed since', children = {makePatch(args.endversion)}},
			Cell{
				name = 'Artist',
				children = {args.artist and Link{link = ':Category:Art by ' .. args.artist, children = {args.artist}} or nil}
			},
			hasAttributes and Title{children = {'Attributes'},} or nil,
			hasAttributes and Breakdown{
				children = WidgetUtil.collect(
					makeAttribute('Mana_Cost_hs.png', 'Mana', args.cost),
					makeAttribute(string.lower(args.type or '') == 'weapon' and 'Weapon.png' or 'AttackIcon.png',
						'Attack', args.attack),
					args.hp and makeAttribute('HitPointIcon.png', 'Hit Points', args.hp)
						or makeAttribute('Shield.png', 'Durability', args.durability)
				),
				classes = {'infobox-center'}
			} or nil,
			args.effect and Title{children = {'Effect'}},
			args.effect and Center{children = {args.effect}}
		)
	elseif id == 'cost' or id == 'attack' then return {}
	elseif id == 'type' then
		return {
			Cell{name = 'Class', children = {args.class}, options = {makeLink = true}},
			Cell{name = 'Type', children = {args.type}, options = {makeLink = true}},
			Cell{name = 'Subtype', children = {args.subtype}, options = {makeLink = true}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local postfix = ' Cards'
	return Array.append({},
		'Cards',
		args.class and (args.class .. postfix) or nil,
		args.type and (args.type .. postfix) or nil,
		args.subtype and (args.subtype .. postfix) or nil,
		args.rarity and (args.rarity .. postfix) or nil,
		args.set and (args.set .. postfix) or nil,
		args.artist and ('Art by ' .. args.artist) or nil
	)
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'card',
		image = args.image,
		extradata = {
			summonedby = args.summonedby,
			chosenfrom = args.chosenfrom,
			class = args.class,
			cost = args.cost,
			rarity = args.rarity,
			subtype = args.subtype,
			atk = args.attack,
			durability = args.durability,
			hitpoints = args.hp or args.durability,
			description = args.description,
			effect = args.effect,
			startversion = args.startversion,
			endversion = args.endversion,
			set = args.set,
			artist = args.artist,
		},
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('card_' .. self.name, Json.stringifySubTables(lpdbData))
end

return CustomUnit
