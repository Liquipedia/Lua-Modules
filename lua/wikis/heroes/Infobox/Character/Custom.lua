---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
local Lua = require('Module:Lua')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/Infobox/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Breakdown = Widgets.Breakdown
local Table = Widgets.Table

---@class HeroesCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class HeroesCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller HeroesCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character.args.informationType = 'Hero'
	character:setWidgetInjector(CustomInjector(character))

	return character:createInfobox()
end

local function getRoleIcon(role)
	if not role then return nil end
	return Image.display('Heroes-Roles-' .. role .. '.webp', nil, {alt = role, size = 50, link = ''})
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'role' or id == 'class' then
		return {}
	elseif id == 'custom' then
		local makeBreakdownCell = function(name, value)
			return '<b>' ..name .. '</b><br/>' .. (value or '')
		end
		Array.appendWith(widgets,
			Breakdown{classes = {'infobox-center'}, children = {
				makeBreakdownCell('Universe', Template.safeExpand(mw.getCurrentFrame(), 'Faction icon', {args.universe})),
				makeBreakdownCell('Role', getRoleIcon(args.role)),
				makeBreakdownCell('Attack', table.concat({args.attacktype, args.attacktype2}, ' and ')),
			}},
			Cell{name = 'Cost', content = {
				Image.display('HotSGold.png', nil, {alt = 'Gold', size = 16, link = ''}) .. ' ' .. (args.costgold or '?'),
				Image.display('HotSGems.png', nil, {alt = 'Gems', size = 16, link = ''}) .. ' ' .. (args.costgem or '?'),
			}},
			Title{children = 'Stats'},
			Cell{name = args.armortype or 'Armor', content = {args.armor}},
			Cell{name = 'Attack Range', content = {args.attackrange}},
			Cell{name = 'Attacks Per Second', content = {args.attackspeed}},
			Title{children = 'Stats Change per Level'},
			Table{
				rows = {
					{'', 'Initial', 'Change/Level'},
					{'Attack Damage', args.damage, args.damagelvl},
					{'Life', args.hp, args.hplvl},
					{'Life Regen', args.hpreg, args.hpreglvl},
					{'Mana', args.energy, args.energylvl},
					{'Mana Regen', args.energyreg, args.energyreglvl},
				},
				options = {
					columns = 3,
					columnOptions = {
						[1] = {classes = {'infobox-cell-3', 'infobox-description'}},
						[2] = {classes = {'infobox-cell-3', 'infobox-center'}},
						[3] = {classes = {'infobox-cell-3', 'infobox-center'}},
					},
				}
			}
		)
	end

	return widgets
end

function CustomCharacter:subHeader(args)
	return args.herotitle
end

---@param lpdbData table
---@param args table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.role = args.role

	return lpdbData
end

return CustomCharacter
