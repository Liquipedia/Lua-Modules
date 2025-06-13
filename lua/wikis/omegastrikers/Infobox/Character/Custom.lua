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

---@class OmegastrikersCharacterInfobox: CharacterInfobox
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
			Cell{
				name = 'Cost',
				content = {'[[File:Omega Strikers Striker Credits.png|20px]] ' .. args.strikercredits ..
						'  [[File:Omega Strikers Ody Points.png|20px]] ' .. args.odypoints}
			},
			Cell{name = 'Affiliation', content = {'[[File:' .. args.affiliation .. ' allmode.png|20px]] ' .. args.affiliation}
			},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactors}},
			Title{children = 'Abilities'},
			Cell{name = 'Primary', content = {'[[File:' .. args.name .. ' - Primary.png|20px]] ' .. args.primary}},
			Cell{name = 'Secondary', content = {'[[File:' .. args.name .. ' - Secondary.png|20px]] ' .. args.secondary}},
			Cell{name = 'Special', content = {'[[File:' .. args.name .. ' - Special.png|20px]] ' .. args.special}}
		)
	end

	return widgets
end

return CustomCharacter
