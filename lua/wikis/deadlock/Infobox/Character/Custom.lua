---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')

local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class DeadlockHeroInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local character = CustomHero(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Hero'
	if character.args.damagebullet and character.args.bps then
		character.args.dps = character.args.dps or (character.args.damagebullet * character.args.bps)
	end

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
			Title{children = 'Vitality'},
			Cell{name = 'Health', content = {args.basehealth}},
			Cell{name = 'Health Regeneration', content = {args.basehealthregen}},
			Cell{name = 'Bullet Resistance', content = {args.resistancebullet .. '%'}},
			Cell{name = 'Spirit Resistance', content = {args.resistancespirit .. '%'}},
			Cell{name = 'Move Speed', content = {args.speedmove .. 'm/s'}},
			Cell{name = 'Sprint Speed', content = {args.speedsprint .. 'm/s'}},
			Cell{name = 'Stamina', content = {args.stamina}}
		)

		Array.appendWith(
			widgets,
			Title{children = 'Weapon'},
			Cell{name = 'DPS', content = {args.dps}},
			Cell{name = 'Bullet Damage', content = {args.damagebullet}},
			Cell{name = 'Bullets per Seconds', content = {args.bps}},
			Cell{name = 'Ammo', content = {args.ammo}},
			Cell{name = 'Light Melee', content = {args.damagemeleelight}},
			Cell{name = 'Heavy Melee', content = {args.damagemeleeheavy}}
		)
		return widgets
	end

	return widgets
end

---@param lpdbData table
---@param args table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.extradata.name = args.name
	lpdbData.extradata.resistancebullet = args.resistancebullet
	lpdbData.extradata.resistancespirit = args.resistancespirit
	lpdbData.extradata.basehealth = args.basehealth
	lpdbData.extradata.basehealthregen = args.basehealthregen
	lpdbData.extradata.speedmove = args.speedmove
	lpdbData.extradata.speedsprint = args.speedsprint
	lpdbData.extradata.stamina = args.stamina
	lpdbData.extradata.dps = args.dps
	lpdbData.extradata.bps = args.bps
	lpdbData.extradata.ammo = args.ammo
	lpdbData.extradata.damagebullet = args.damagebullet
	lpdbData.extradata.damagemeleelight = args.damagemeleelight
	lpdbData.extradata.damagemeleeheavy = args.damagemeleeheavy
	lpdbData.extradata.playable = tostring(Logic.nilOr(Logic.readBoolOrNil(args.playable), true))
	lpdbData.extradata.removed = tostring(Logic.readBool(args.removed))

	return lpdbData
end

return CustomHero
