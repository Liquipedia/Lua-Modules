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
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TYPE_TO_COST_TYPE = {
	consumable = 'gold',
	weapon = 'gold',
	armor = 'gold',
	accessory = 'gold',
	deed = 'gold',
	item = 'gold',
	default = 'mana',
}

---@class ArtifactUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class ArtifactUnitInfoboxWidgetInjector: WidgetInjector
---@field caller ArtifactUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Card'
	unit:setWidgetInjector(CustomInjector(unit))

	return HtmlWidgets.Fragment{
		unit:createInfobox(),
		CustomUnit._buildDescription(unit.args),
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local makePatch = function(input)
			if not input then return end
			return Link{
				link = 'Patch ' .. input,
				children = {input},
			}
		end
		return WidgetUtil.collect(
			Cell{name = 'Color', children = {args.color}, options = {makeLink = true}},
			Cell{name = 'Rarity', children = {args.rarity}, options = {makeLink = true}},
			Cell{name = 'Hero Card', children = {args.hero}, options = {makeLink = true}},
			Cell{name = 'Signature Card', children = {args.signature}, options = {makeLink = true}},
			Cell{name = 'Set', children = {args.set}, options = {makeLink = true}},
			Cell{name = 'Introduced', children = {makePatch(args.startversion)}},
			Cell{name = 'Removed since', children = {makePatch(args.endversion)}},
			Cell{name = 'Illustrator', children = {args.illustrator}, options = {makeLink = true}},
			args.effect and Title{children = 'Effect'} or nil,
			args.effect and Center{children = {args.effect}} or nil
		)
	elseif id == 'cost' then
		return {
			Cell{name = 'Cost', children = {caller:getCostDisplay()}},
		}
	elseif id == 'type' then
		return {
			Cell{name = 'Type', children = {args.type}, options = {makeLink = true}},
		}
	elseif id == 'attack' then
		return {
			Cell{name = Link{link = 'Damage'}, children = {args.damage}},
		}
	elseif id == 'defense' then
		return {
			Cell{name = Link{link = 'Armor'}, children = {args.armor}},
			Cell{name = Link{link = 'Health'}, children = {args.health}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local postfix = ' Cards'
	local costType = self:getCostType()
	return Array.append({},
		'Cards',
		'Cards costing ' .. self:getCostDisplay(),
		(costType == TYPE_TO_COST_TYPE.default and 'Item' or '') .. postfix,
		args.type and (args.type .. postfix) or nil,
		args.color and (args.color .. postfix) or nil,
		args.color and args.type and (args.color .. ' ' .. args.type .. postfix) or nil,
		args.rarity and (args.rarity .. postfix) or nil,
		args.hero and ('Signature' .. postfix) or nil,
		args.set and (args.set .. postfix) or nil,
		args.illustrator and ('Cards illustrated by ' .. args.illustrator) or nil
	)
end

---@return string
function CustomUnit:getCostType()
	return TYPE_TO_COST_TYPE[(self.args.type or ''):lower()] or TYPE_TO_COST_TYPE.default
end

---@return string
function CustomUnit:getCostDisplay()
	local costType = self:getCostType()
	return self.args[costType] .. ' ' .. costType .. (costType ~= TYPE_TO_COST_TYPE.default and ' coins' or '')
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'card',
		image = args.image,
		extradata = {
			color = args.color,
			cost = args.mana or args.gold,
			rarity = args.rarity,
			type = args.type,
			damage = args.damage,
			armor = args.armor,
			health = args.health,
			effect = args.effect,
			start = args.startversion,
			['end'] = args.endversion,
			illustrator = args.illustrator,
			set = args.set,
			signature = args.signature,
		},
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('card_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@return Widget?
function CustomUnit:_buildDescription()
	local args = self.args
	if not Logic.readBool(args['generate description']) then return end

	local lowerCaseIfExist = function(input)
		return input and (' ' .. input:lower()) or nil
	end

	local attackDefenseInfo = mw.text.listToText(Array.append({},
		args.damage and (args.damage .. ' attack') or nil,
		args.armor and (args.armor .. ' point' .. (tonumber(args.armor) == 1 and '' or 's') .. ' of armor') or nil,
		args.health and (args.health .. ' point' .. (tonumber(args.health) == 1 and '' or 's') .. ' of health') or nil
	), ', ', ' and ')

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			HtmlWidgets.B{children = self.name},
			' is a',
			args.mana and (' ' .. args.mana .. '-mana cost') or nil,
			args.gold and (' ' .. args.gold .. '-gold cost') or nil,
			lowerCaseIfExist(args.color),
			lowerCaseIfExist(args.type),
			attackDefenseInfo and (' with ' .. attackDefenseInfo) or nil,
			'.'
		)
	}
end

return CustomUnit
