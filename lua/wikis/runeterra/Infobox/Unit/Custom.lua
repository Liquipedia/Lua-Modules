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
local Random = Lua.import('Module:Random')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Link = Lua.import('Module:Widget/Basic/Link')
local Image = require('Module:Widget/Image/Icon/Image')

---@class RuneterraUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class RuneterraUnitInfoboxWidgetInjector: WidgetInjector
---@field caller RuneterraUnitInfobox
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
		return {
			Cell{name = 'Illustrator', children = {args.illustrator}, options = {makeLink = true}},
		}
	elseif id == 'type' then
		return {
			Cell{name = 'Type', children = {args.type}, options = {makeLink = true}},
			Cell{name = 'Subtype', children = {args.subtype}, options = {makeLink = true}},
			Cell{name = 'Region', options = {separator = ' '}, children = args.region and {
				Image{size = '25px', link = args.region, imageLight = 'Runeterra Region ' .. args.region .. '.png'},
				Link{link = args.region},
			}or nil},
			Cell{name = 'Rarity', children = {args.rarity}, options = {makeLink = true}},
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
		args.region and (args.region .. postfix) or nil,
		args.type and (args.type .. postfix) or nil,
		args.region and args.type and (args.region .. ' ' .. args.type .. postfix) or nil,
		args.illustrator and ('Cards illustrated by ' .. args.illustrator) or nil
	)
end

---@param args table
function CustomUnit:setLpdbData(args)
	local readFromLorCardData = function(key)
		if Logic.isEmpty(args.code) then return end
		return mw.getCurrentFrame():callParserFunction{name = '#getlorcarddata:' .. args.code, args = {key}}
	end

	local cardType = readFromLorCardData('type')
	local rarity = readFromLorCardData('rarity')
	local description = readFromLorCardData('desc_raw')
	if description then
		description = description:gsub('%|', '&#124;')
	end

	local lpdbData = {
		name = self.name,
		information = readFromLorCardData('region'),
		type = 'card',
		image = args.image,
		extradata = {
			randomnumber = Random.randomIntFromTo{from = 1, to = 100000},
			attack = cardType ~= 'Spell' and readFromLorCardData('attack') or nil,
			health = cardType ~= 'Spell' and readFromLorCardData('health') or nil,
			code = args.code,
			type = args.type,
			subtype = readFromLorCardData('subtype'),
			illustrator = readFromLorCardData('artist_name'),
			cost = readFromLorCardData('cost'),
			region = readFromLorCardData('region'),
			startversion = args.startversion,
			endversion = args.endversion,
			expansion = args.expansion,
			fearsome = args.fearsome,
			challenger = args.challenger,
			lastbreath = args.lastbreath,
			ephemeral = args.ephemeral,
			rarity = rarity and String.upperCaseFirst(rarity:lower()) or nil,
			description = description,
		},
	}

	mw.ext.LiquipediaDB.lpdb_datapoint('card_' .. self.name, Json.stringifySubTables(lpdbData))
end

return CustomUnit
