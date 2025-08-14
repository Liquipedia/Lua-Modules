---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class WildcardChampionInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local character = CustomHero(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Champion'

	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Title{children = 'Basic Attributes'},
			Cell{name = 'Health', children = {args.health}},
			Cell{name = 'Damage per second', children = {args.dps}},
			Cell{name = 'Move Speed', children = {args.movespeed}},
			Cell{name = 'House', children = {args.house}},
			Title{children = 'Basic Stats'},
			Cell{name = 'Healing', children = {args.healing}},
			Cell{name = 'Mobility', children = {args.mobility}},
			Cell{name = 'Offense', children = {args.offense}},
			Cell{name = 'Defense', children = {args.defense}},
			Cell{name = 'Utility', children = {args.utility}}
		)
		return widgets
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.extradata.house = args.house
	lpdbData.extradata.health = args.health
	lpdbData.extradata.damagepersecond = args.dps
	lpdbData.extradata.movespeed = args.movespeed
	lpdbData.extradata.healing = args.healing
	lpdbData.extradata.mobility = args.mobility
	lpdbData.extradata.offense = args.offense
	lpdbData.extradata.defense = args.defense
	lpdbData.extradata.utility = args.utility

	return lpdbData
end

return CustomHero
