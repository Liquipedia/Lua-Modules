---
-- @Liquipedia
-- page=Module:Infobox/Unit/Brawler/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterWinLoss = Lua.import('Module:CharacterWinLoss')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Math = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class BrawlStarsUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Brawler'
	return unit:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'caption' and not String.isEmpty(args.min) then
		table.insert(widgets, Center{children = {args.quote}})
	elseif id == 'type' then
		return {
			Cell{name = 'Rarity', children = {args.rarity}},
			Cell{name = 'Class', children = {args.class}},
			Cell{name = 'Voice Actor(s)', children = {self.caller:_getVoiceActors()}},
			Cell{name = 'Release Date', children = {args.releasedate}},
			Cell{name = 'Health', children = {args.hp}},
			Cell{name = 'Movespeed', children = {args.movespeed}}
		}
	elseif id == 'requirements' then
		return {
			Cell{name = 'Price', children = {args.price}},
		}
	elseif id == 'attack' then
		return {}
	elseif id == 'defense' then
		return {}
	elseif id == 'custom' then
		Array.appendWith(widgets, self.caller:_getTypeCells())
	end

	return widgets
end

---@return Widget[]
function CustomUnit:_getTypeCells()
	local args = self.args
	return {
		Title{children = 'Weapon & Super'},
		Cell{name = 'Primary Weapon', children = {args.attack}},
		Cell{name = 'Super Ability', children = {args.super}},
		Title{children = 'Abilities'},
		Cell{name = 'Traits', children = {args.trait}},
		Cell{name = 'Gadgets', children = {args.gadget}},
		Cell{name = 'Star Powers', children = {args.star}},
		Cell{name = 'Hypercharge', children = {args.hypercharge}},
		Cell{name = 'Buffies', children = {args.buffies}}
	}
end

---@return string[]
function CustomUnit:_getVoiceActors()
	local args = self.args
	local voiceActors = {}
	for voiceActorKey, voiceActor in Table.iter.pairsByPrefix(args, 'voice', {requireIndex = false}) do
		local flag = args[voiceActorKey .. 'flag']
		if flag then
			voiceActor = Flags.Icon{flag = flag} .. ' ' .. voiceActor
		end
		table.insert(voiceActors, voiceActor)
	end
	return voiceActors
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = args.name or self.pagename,
		type = 'brawler',
		image = args.image,
		date = args.releasedate,
		information = 'brawler',
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{}
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('brawler_' .. (args.name or self.pagename), lpdbData)
end

---@param args table
---@return table
function CustomUnit:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.append({'Brawlers'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' brawlers') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' brawlers') or nil
	)
end

return CustomUnit
