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
local Center = Widgets.Center
local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class IlluvCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Illuvial'
	character.args.image = 'Illuvium ' .. (character.args.name or '') .. '.png'
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
			Cell{name = 'Affinity', children = {args.affinity}},
			Title{children = 'Stats'},
			Center{children = {Link{
				link = 'Glossary',
				children = HtmlWidgets.Span{children = {
					'Glossary'}
				}
			}}},
			Title{children = 'Health'},
			Cell{name = 'Max Health', children = {args.maxhealth}},
			Cell{name = 'Regeneration', children = {args.regeneration}},
			Cell{name = 'Heal Efficiency', children = {args.healefficiency}},
			Title{children = 'Energy'},
			Cell{name = 'Starting Energy', children = {args.startingenergy}},
			Cell{name = 'Regeneration', children = {args.regeneration}},
			Cell{name = 'Gain Efficiency', children = {args.gainefficiency}},
			Cell{name = 'Omega Cost', children = {args.omegacost}},
			Cell{name = 'Omega Power', children = {args.omegapower}},
			Cell{name = 'Omega Range', children = {args.omegarange}},
			Cell{name = 'On Activation', children = {args.onactivation}},
			Title{children = 'Resistances'},
			Cell{name = 'Physical Resist', children = {args.physicalresist}},
			Cell{name = 'Energy Resist', children = {args.energyresist}},
			Cell{name = 'Tenacity', children = {args.tenacity}},
			Cell{name = 'Willpower', children = {args.willpower}},
			Cell{name = 'Grit', children = {args.grit}},
			Cell{name = 'Resolve', children = {args.resolve}},
			Cell{name = 'Dodge', children = {args.dodge}},
			Cell{name = 'Vulnerability', children = {args.vulnerability}},
			Cell{name = 'Physical Piercing', children = {args.physicalpiercing}},
			Cell{name = 'Energy Piercing', children = {args.energypiercing}},
			Cell{name = 'Thorns', children = {args.thorns}},
			Cell{name = 'Starting Shield', children = {args.startingshield}},
			Cell{name = 'Crit Reduction', children = {args.critreduction}},
			Title{children = 'Attack'},
			Cell{name = 'Physical Damage', children = {args.physicaldamage}},
			Cell{name = 'Energy Damage', children = {args.energydamage}},
			Cell{name = 'Pure Damage', children = {args.puredamage}},
			Cell{name = 'Speed', children = {args.speed}},
			Cell{name = 'Hit Chance', children = {args.hitchance}},
			Cell{name = 'Crit Chance', children = {args.critchance}},
			Cell{name = 'Crit Amplification', children = {args.critamplification}},
			Cell{name = 'Range', children = {args.range}},
			Cell{name = 'Physical Vamp', children = {args.physicalvamp}},
			Cell{name = 'Energy Vamp', children = {args.energyvamp}},
			Cell{name = 'Pure Vamp', children = {args.purevamp}}
		)
	end

	return widgets
end

return CustomCharacter

