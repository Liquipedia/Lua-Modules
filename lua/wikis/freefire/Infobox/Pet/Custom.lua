-- @Liquipedia
-- page=Module:Infobox/Pet/Custom
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local Pet = Lua.import('Module:Infobox/Pet')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class FreefirePetInfobox: PetInfobox
local CustomPet = Class.new(Pet)
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
				Cell{name = 'Skill Mode', children = {args.type or args.mode}}
			)
		end
	end

	return widgets
end

return CustomPet
