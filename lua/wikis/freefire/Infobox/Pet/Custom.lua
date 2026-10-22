---
-- @Liquipedia
-- page=Module:Infobox/Pet/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class FreefirePetInfobox: CharacterInfobox
local CustomPet = Class.new(Character)
---@class FreefirePetInfoboxWidgetInjector: WidgetInjector
---@field caller FreefirePetInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomPet.run(frame)
	local pet = CustomPet(frame)
	pet:setWidgetInjector(CustomInjector(pet))
	return pet:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Species / Type', children = {args.species}}
		)

		if Logic.isNotEmpty(args.ability) then
			Array.appendWith(widgets,
				Title{children = 'Special Ability'},
				Cell{name = 'Legend Type', children = {args.ability}},
				Cell{name = 'Skill Mode', children = {args.mode}}
			)
		end
	end

	return widgets
end

---@param args table
---@return string[]
function CustomPet:getWikiCategories(args)
	return {'Pets'}
end

---@param lpdbData table
---@param args table
---@return table
function CustomPet:addToLpdb(lpdbData, args)
	lpdbData.type = 'pet'
	lpdbData.extradata.species = args.species
	lpdbData.extradata.ability = args.ability
	lpdbData.extradata.mode = args.mode

	return lpdbData
end

return CustomPet
