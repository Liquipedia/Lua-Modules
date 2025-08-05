---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ApexlegendsCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	return character:createInfobox()
end
---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Home World', content = {args.homeworld}},
			Title{children = 'Abilities'},
			Cell{name = 'Legend Type', content = {args.legendtype}},
			Cell{name = 'Passive', content = {'[[File:' .. args.name .. ' - Passive.png|20px]] ' .. args.passive}},
			Cell{name = 'Tactical', content = {'[[File:' .. args.name .. ' - Active.png|20px]] ' .. args.active}},
			Cell{name = 'Ultimate', content = {'[[File:' .. args.name .. ' - Ultimate.png|20px]] ' .. args.ultimate}}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.class = args.legendtype
	return lpdbData
end

return CustomCharacter
