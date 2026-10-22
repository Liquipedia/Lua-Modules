---
-- @Liquipedia
-- page=Module:Infobox/Pet/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
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
				Cell{name = 'Skill Mode', children = {args.type or args.mode}}
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

---@param args table
function CustomPet:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		type = 'pet',
		date = args.releasedate,
		extradata = {
			species = args.species,
			ability = args.ability,
			mode = args.type or args.mode,
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('pet_' .. self.name, Json.stringifySubTables(lpdbData))
end

return CustomPet
