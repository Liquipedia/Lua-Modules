---
-- @Liquipedia
-- page=Module:Infobox/Extension/BuildingUnitShared
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--shared parts for warcraft infoboxes unit and building to de-duplicate code

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local AttackIcon = require('Module:AttackIcon')
local Faction = require('Module:Faction')
local GameClock = require('Module:GameClock')
local Logic = require('Module:Logic')
local Math = require('Module:MathUtil')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Widgets = require('Module:Widget/All')
local BreakDown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomBuildingUnit = {}

local HP_REGEN_TYPE_DISPLAY = {'(always)', 'on Blight', 'at Night'}
local MELEE = 'Melee'
local AOE_VALUE = {
	artillery = 2,
	aline = 2,
	msplash = 2,
	mbounce = 3,
	mline = 1,
}
local AREA_VALUE_TO_AREA_DESCRIPTION = {
	[0] = nil, nil, 'Area', 'Bounce', nil, nil,
	'Area', 'Bounce', 'Area', 'Area', 'Area', 'Area/Bounce',
	'Bounce', 'Bounce', 'Bounce/Area', 'Bounce'
}
local EXTRA_RACE_SUPPORT = {
	hu = 'human',
	orcs = 'orc',
	['night elves'] = 'nightelf',
	ud = 'undead',
	creeps = 'creeps',
	neutral = 'creeps',
	c = 'creeps',
}

---@param args table
---@param options {display: boolean?}?
---@return string?
---@overload fun(args: table, options: {display: boolean?}?): table?
function CustomBuildingUnit.hitPointsRegeneration(args, options)
	options = options or {}

	local hpRegenData = {
		regen = tonumber(args.hpregen) or 0,
		bonus = tonumber(args.hpregen_bonus) or 0,
		type = tonumber(args.hpregentype),
		typeDisplay = HP_REGEN_TYPE_DISPLAY[tonumber(args.hpregentype)],
	}

	if hpRegenData.regen == 0 or not hpRegenData.typeDisplay then
		return not options.display and hpRegenData or nil
	end

	hpRegenData.increased = hpRegenData.regen + hpRegenData.bonus

	if not options.display then return hpRegenData end

	local display = hpRegenData.regen .. ' '
	if hpRegenData.bonus > 0 then
		display = display .. '(' .. hpRegenData.increased .. ') '
	end

	return display .. (hpRegenData.typeDisplay or '')
end

---@class ManaValuesWarcraftInfoboxBuildingUnit
---@field mana number?
---@field increasedMana number?
---@field initialMana number?
---@field initialManaDisplay string?
---@field manaDisplay string?
---@field manaRegen number?
---@field increasedManaRegen number?
---@field manaRegenDisplay string?

---@param args table
---@return ManaValuesWarcraftInfoboxBuildingUnit
function CustomBuildingUnit.manaValues(args)
	local mana = tonumber(args.mana) or 0
	if mana == 0 then return {} end

	local manaBonus = tonumber(args.mana_bonus) or 0
	local increasedMana = mana + manaBonus
	local manaDisplay = mana .. (manaBonus > 0 and (' (' .. increasedMana .. ')') or '')

	local initialMana = tonumber(args.manastart) or mana
	local initialManaDisplay = initialMana ..
		(manaBonus > 0 and (' (' .. Math.round(initialMana / mana * increasedMana, 2) .. ')') or '')

	local manaRegen = tonumber(args.manaregen) or 0
	local manaRegenBonus = tonumber(args.manaregen_bonus) or 0
	local increasedManaRegen = Math.round(manaRegen + manaRegenBonus, 2)
	local manaRegenDisplay = Math.round(manaRegen, 2) ..
		(manaRegenBonus > 0 and (' (' .. increasedManaRegen .. ')') or '')

	return {
		mana = mana,
		increasedMana = increasedMana,
		manaDisplay = manaDisplay,
		initialMana = initialMana,
		initialManaDisplay = initialManaDisplay,
		manaRegen = manaRegen,
		increasedManaRegen = increasedManaRegen,
		manaRegenDisplay = manaRegenDisplay
	}
end

---@param args table
---@return Widget[]
function CustomBuildingUnit.attackDisplay(args)
	local numberOfAttacks = tonumber(args.attacksenabled) or 0
	if numberOfAttacks == 0 then return {} end
	-- due to legacy reasons the following hacky switch
	if numberOfAttacks <= 2 then
		numberOfAttacks = 1
	else
		numberOfAttacks = 2
	end

	local attackIndexes = Array.range(1, numberOfAttacks)

	local attackData = Array.map(attackIndexes, function(attackIndex)
		return CustomBuildingUnit.parseAttackInput(args, attackIndex)
	end)

	local toWidget = function(desc, key)
		local data = Array.map(attackIndexes, function(attackIndex) return attackData[attackIndex][key] or '' end)
		if Array.all(data, Logic.isEmpty) then
			return nil
		end
		return BreakDown{contentClasses = {content1 = {'infobox-description'}}, children = {desc, unpack(data)}}
	end

	return Array.append({Title{children = 'Combat'}},
		toWidget('Requirement:', 'requirement'),
		toWidget('[[Attack Damage|Damage]]:', 'attackTypeAndDamage'),
		toWidget(CustomBuildingUnit.getAreaHeader(args) or '', 'area'),
		toWidget('Area Targets:', 'areaTargets'),
		toWidget('[[Attack Range|Range]]:', 'range'),
		toWidget('[[Weapon Type]]:', 'weaponType'),
		toWidget('[[Attack Speed|Cooldown]]:', 'coolDown'),
		toWidget('[[Targeting|Targets]]:', 'targets')
	)
end

---@param args table
---@param attackIndex number
---@return table<string, string>
function CustomBuildingUnit.parseAttackInput(args, attackIndex)
	local postFix = attackIndex == 1 and '' or attackIndex

	local attackTypeAndDamage
	local attackIcon = AttackIcon.run(args['attacktype' .. postFix])
	if attackIcon ~= AttackIcon.run() then
		attackTypeAndDamage = attackIcon .. ' ' .. CustomBuildingUnit.calculateMinDamage(args, postFix)
			.. ' - ' .. CustomBuildingUnit.calculateMaxDamage(args, postFix)

		local bonusDamage = tonumber(args['damage_bonus' .. postFix]) or 0
		local attackUpgradesDamage = tonumber(args['attack_upgrades' .. postFix]) or 0
		if bonusDamage + attackUpgradesDamage > 0 then
			attackTypeAndDamage = attackTypeAndDamage .. ' (' ..
				CustomBuildingUnit.calculateIncreasedMinDamage(args, postFix) .. ' - ' ..
				CustomBuildingUnit.calculateIncreasedMaxDamage(args, postFix) .. ')'
		end
	end

	local rangeValue = tonumber(args['range' .. postFix] or args.range)
	local rangeBonus = tonumber(args.range_bonus) or 0
	local range
	if rangeValue and rangeBonus > 0 then
		range = rangeValue .. ' (' .. (rangeValue + rangeBonus) .. ')'
	end

	local damagePoint = tonumber(args['dmgpoint' .. postFix]) or 0
	local backSwingPoint = tonumber(args['backswingpoint' .. postFix]) or 0
	local coolDownValue = tonumber(args['cooldown' .. postFix]) or 0
	local coolDown = tostring(coolDownValue)
	if backSwingPoint > 0 then
		coolDown = Abbreviation.make{
			text = coolDown,
			title = 'Attack animation: ' .. (damagePoint / backSwingPoint),
		}
	end

	local attackSpeedBonus = tonumber(args.attackspeed_bonus) or 0
	if attackSpeedBonus > 0 then
		local attackSpeedBonusPlus1 = 1 + attackSpeedBonus
		local animation = (damagePoint / attackSpeedBonusPlus1) .. '/' .. (backSwingPoint / attackSpeedBonusPlus1)
		coolDown = coolDown .. ' (' .. Abbreviation.make{
			text = coolDownValue / attackSpeedBonusPlus1,
			title = 'Attack animation: ' .. animation
		} .. ')'
	end

	local data = {
		attackTypeAndDamage = attackTypeAndDamage,
		requirement = args['attackrequirement' .. attackIndex],
		range = range or rangeValue,
		weaponType = args['weapontype' .. postFix] or args.weapontype,
		targets = String.convertWikiListToHtmlList(args['targets' .. postFix] or args.targets),
		coolDown = coolDown,
	}

	if AOE_VALUE[args['weapontype' .. postFix]] then
		Table.mergeInto(data, CustomBuildingUnit.parseAoe(args, postFix))
	end

	return data
end

---@param args table
---@param postFix string|number
---@return table<string, string>
function CustomBuildingUnit.parseAoe(args, postFix)
	local show = AOE_VALUE[(args['weapontype' .. postFix] or ''):lower()] ~= nil
	if not show then return {} end

	local areaTargets = String.convertWikiListToHtmlList(args['areatargets' .. postFix])
	local areaValue = tonumber(args['area' .. postFix]) or 0
	if areaValue <= 0 or args.weapontype == 'mline' then
		return {areaTargets = areaTargets}
	end

	local area
	if args.weapontype == 'mbounce' then
		area = mw.html.create()
			:tag('b'):wikitext('Area: '):done()
			:wikitext(areaValue)
		if args.areamed then
			area
				:wikitext('<br>')
				:tag('b'):wikitext('Targets: '):done()
				:wikitext(args['target_count' .. postFix] or 0)
		end
		if args.areasm then
			local damageLoss = (tonumber(args['target_count' .. postFix]) or 0) * 100
			area
				:wikitext('<br>')
				:tag('b'):wikitext('Damage Loss: '):done()
				:wikitext(damageLoss .. '%')
		end
	else
		area = mw.html.create()
			:tag('b'):wikitext('Full Dmg: '):done()
			:wikitext(areaValue)
		if args.areamed then
			local dmgmed = tonumber(args.dmgmed or 0.5) * 100
			area
				:wikitext('<br>'):tag('b'):wikitext(dmgmed .. '% Dmg: '):done()
				:wikitext(args['areamed' .. postFix] or 0)
		end
		if args.areasm then
			local dmgsm = tonumber(args.dmgsm or 0.25) * 100
			area
				:wikitext('<br>'):tag('b'):wikitext(dmgsm .. '% Dmg: '):done()
				:wikitext(args['areasm' .. postFix] or 0)
		end
	end

	return {area = tostring(area), areaTargets = areaTargets}
end

---@param args table
---@return string?
function CustomBuildingUnit.getAreaHeader(args)
	local aoeValue = AOE_VALUE[(args.weapontype or ''):lower()] or 0
	local aoeValue2 = AOE_VALUE[(args.weapontype2 or ''):lower()] or 0

	return AREA_VALUE_TO_AREA_DESCRIPTION[4 * (aoeValue + aoeValue2)]
end

---@param args table
---@param index number|string|nil
---@return number
function CustomBuildingUnit.calculateMinDamage(args, index)
	index = index or ''

	local baseDamage = tonumber(args['dmgbase' .. index]) or 0
	local diceDamage = tonumber(args['dmgdice' .. index]) or 1

	return baseDamage + diceDamage
end

---@param args table
---@param index number|string|nil
---@return number
function CustomBuildingUnit.calculateMaxDamage(args, index)
	index = index or ''

	local baseDamage = tonumber(args['dmgbase' .. index]) or 0
	local diceDamage = tonumber(args['dmgdice' .. index]) or 1
	local sidesDamage = tonumber(args['dmgsides' .. index] or args.dmgsides) or 2

	return baseDamage + (diceDamage * sidesDamage)
end

---@param args table
---@param index number|string|nil
---@return number
function CustomBuildingUnit.calculateIncreasedMinDamage(args, index)
	index = index or ''

	local bonusDamage = tonumber(args['damage_bonus' .. index]) or 0
	local attackUpgradesDamage = tonumber(args['attack_upgrades' .. index]) or 0

	return CustomBuildingUnit.calculateMinDamage(args, index) + bonusDamage + attackUpgradesDamage
end

---@param args table
---@param index number|string|nil
---@return number
function CustomBuildingUnit.calculateIncreasedMaxDamage(args, index)
	index = index or ''

	local baseDamage = tonumber(args['dmgbase' .. index]) or 0
	local diceDamage = tonumber(args['dmgdice' .. index]) or 1
	local sidesDamage = tonumber(args.dmgsides) or 2
	local bonusDamage = tonumber(args['damage_bonus' .. index]) or 0
	local attackUpgradesDamage = tonumber(args['attack_upgrades' .. index]) or 0

	return baseDamage + bonusDamage + (diceDamage + attackUpgradesDamage) * sidesDamage
end

function CustomBuildingUnit.mercenaryStats(args)
	if CustomBuildingUnit.raceValue(args.race) ~= 'creeps' or Logic.readBool(args.cannot_be_built)
		or not args.stockstart then

		return
	end

	return {
		Title{children = 'Mercenary Stats'},
		Cell{name = 'Stock Maximum', content = {args.stock}},
		Cell{name = 'Stock Start Delay', content = {Abbreviation.make{
			text = args.stockstart .. 's', title = 'First available at ' .. GameClock.run(args.stockstart)}}},
		Cell{name = 'Replenish Interval', content = {args.stockreplenish}},
		Cell{name = 'Tileset', content = {args.merctileset, args.merctileset2, args.merctileset3}},
	}
end

function CustomBuildingUnit.movement(args, title)
	local speedValue = tonumber(args.speed) or 0
	if speedValue == 0 then return end

	local speed = args.speed or '0'
	local speedBonus = tonumber(args.movementspeed_bonus) or 0
	if speedBonus > 0 then
		speed = speed .. ' (' .. (speedValue + speedBonus) .. ')'
	end

	return {
		Title{children = title},
		Cell{name = '[[Movement Speed|Speed]]', content = {speed}},
		Cell{name = 'Turn Rate', content = {args.turnrate}},
		Cell{name = 'Move Type', content = {args.movetype}},
		Cell{name = 'Collision Size', content = {args.collision}},
		Cell{name = 'Cargo Size', content = {args.cargo_size}},
	}
end

---@param race string?
---@return string?
function CustomBuildingUnit.raceValue(race)
	if not race then return end

	race = (race or ''):lower()

	return (Faction.toName(Faction.read(race))
		or EXTRA_RACE_SUPPORT[race] or race):lower()
end

---@param args table
---@return table<string, string|number|nil>
function CustomBuildingUnit.buildBaseExtraData(args)
	local toIncreasedValue = function(baseKey, bonusKey, factorKey)
		local baseValue = tonumber(args[baseKey]) or 0
		local bonusValue = tonumber(args[bonusKey]) or 0
		local factor = not factorKey and 1 or (tonumber(args[factorKey]) or 0)
		if baseValue > 0 and bonusValue > 0 then
			return baseValue + bonusValue * factor
		end
	end

	local calculateReducedCooldown = function(postfix)
		postfix = postfix or ''
		local bonus = tonumber(args.attackspeed_bonus) or 0
		--avoid division by 0
		if bonus == -1 then return end
		local cooldown = tonumber(args['cooldown' .. postfix]) or 0
		return cooldown / (bonus + 1)
	end

	return {
		race = CustomBuildingUnit.raceValue(args.race),
		builtfrom = args.builtfromlink or args.builtfrom,
		hitpoints = args.hp,
		hpregeneration = args.hpregen,
		manapoints = args.mana,
		manaregeneration = args.manaregen,
		armor = args.armor,
		armortype = args.armortype,
		unitlevel = args.level,
		sightradiusday = args.daysight,
		sightradiusnight = args.nightsight,
		speed = args.speed,
		collisionsize = args.collision,
		attacktype = args.attacktype,
		attacktype2 = args.attacktype2,
		weapontype = args.weapontype,
		weapontype2 = args.weapontype2,
		cooldown = args.cooldown,
		cooldown2 = args.cooldown2,
		range = args.range == MELEE and 0 or args.range,
		range2 = args.range2 == MELEE and 0 or args.range2,
		stock = args.stock,
		stockstart = args.stockstart,
		stockreplenish = args.stockreplenish,
		mercenarytileset1 = args.merctileset,
		mercenarytileset2 = args.merctileset2,
		mercenarytileset3 = args.merctileset3,
		increasedhitpoints = toIncreasedValue('hp', 'hitpoint_bonus'),
		increasedhpregeneration = CustomBuildingUnit.hitPointsRegeneration(args).increased,
		increasedmanapoints = toIncreasedValue('mana', 'mana_bonus'),
		increasedarmor = toIncreasedValue('armor', 'armorup', 'armor_upgrades'),
		increasedspeed = toIncreasedValue('speed', 'movementspeed_bonus'),
		increasedmanaregeneration = toIncreasedValue('manaregen', 'manaregen_bonus'),
		mindamage = CustomBuildingUnit.calculateMinDamage(args),
		mindamage2 = CustomBuildingUnit.calculateMinDamage(args, 2),
		maxdamage = CustomBuildingUnit.calculateMaxDamage(args),
		maxdamage2 = CustomBuildingUnit.calculateMaxDamage(args, 2),
		increasedmindamage = CustomBuildingUnit.calculateIncreasedMinDamage(args),
		increasedmindamage2 = CustomBuildingUnit.calculateIncreasedMinDamage(args, 2),
		increasedmaxdamage = CustomBuildingUnit.calculateIncreasedMaxDamage(args),
		increasedmaxdamage2 = CustomBuildingUnit.calculateIncreasedMaxDamage(args, 2),
		increasedrange = toIncreasedValue('range', 'range_bonus'),
		increasedrange2 = toIncreasedValue('range2', 'range_bonus') or toIncreasedValue('range', 'range_bonus'),
		reducedcooldown = calculateReducedCooldown(),
		reducedcooldown2 = calculateReducedCooldown(2),
	}
end

return CustomBuildingUnit
