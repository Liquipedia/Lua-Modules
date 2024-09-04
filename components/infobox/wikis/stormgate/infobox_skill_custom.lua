---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Skill/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local MessageBox = require('Module:Message box')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Skill = Lua.import('Module:Infobox/Skill')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class StormgateSkillInfobox: SkillInfobox
---@field faction string?
local CustomSkill = Class.new(Skill)
local CustomInjector = Class.new(Injector)

local ENERGY_ICON = '[[File:EnergyIcon.gif|link=Energy]]'
local ICON_DEPRECATED = '[[File:Cancelled Tournament.png|link=]]'
local VALID_SKILLS = {
	'Spell',
	'Ability',
	'Trait',
	'Upgrade',
	'Effect',
}

---@param frame Frame
---@return Html
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	assert(Table.includes(VALID_SKILLS, skill.args.informationType), 'Missing or invalid "informationType"')

	skill:setWidgetInjector(CustomInjector(skill))

	skill.faction = Faction.read(skill.args.faction)

	skill:_calculateDamageHealTotalAndDps('damage')
	skill:_calculateDamageHealTotalAndDps('heal')

	skill:_processPatchFromId('introduced')
	skill:_processPatchFromId('deprecated')

	local builtInfobox = skill:createInfobox()

	return mw.html.create()
		:node(builtInfobox)
		:node(CustomSkill._deprecatedWarning(skill.args.deprecatedDisplay))
end

---@param args table
---@return string
function CustomSkill:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {caller:_costDisplay()}},
			Cell{name = 'Recharge Time', content = {args.charge_time and (args.charge_time .. 's') or nil}},
		}
	elseif id == 'duration' then
		return {
			Cell{name = 'Duration', content = {args.duration and (args.duration .. 's') or nil}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = 'Hotkeys', content = {CustomSkill._hotkeys(args.hotkey, args.hotkey2)}},
			Cell{name = 'Macrokeys', content = {CustomSkill._hotkeys(args.macro_key, args.macro_key2)}},
		}
	elseif id == 'custom' then
		local castingTime = tonumber(args.casting_time)

		---@param arr string[]
		---@param trimPattern string?
		---@return string[]
		local makeArrayLinks = function(arr, trimPattern)
			return Array.map(arr, function(value)
				local display = value
				if trimPattern then
					display = display:gsub(trimPattern, '')
				end
				return Page.makeInternalLink({}, display, value)
			end)
		end

		Array.extendWith(widgets, {
				Cell{name = 'Researched From', content = {Page.makeInternalLink({}, args.from)}},
				Cell{name = 'Upgrade Target', content = makeArrayLinks(Array.parseCommaSeparatedString(args.upgrade_target))},
				Cell{name = 'Tech. Requirements', content = makeArrayLinks(Array.parseCommaSeparatedString(args.tech_requirement))},
				Cell{name = 'Building Requirements',
					content = makeArrayLinks(Array.parseCommaSeparatedString(args.building_requirement))},
				Cell{name = 'Unlocks', content = makeArrayLinks(Array.parseCommaSeparatedString(args.unlocks))},
				Cell{name = 'Target', content = makeArrayLinks(Array.parseCommaSeparatedString(args.target))},
				Cell{name = 'Casting Time', content = {castingTime and (castingTime .. 's') or nil}},
				Cell{name = 'Effect', content = makeArrayLinks(Array.parseCommaSeparatedString(args.effect), ' %(effect%)$')},
				Cell{name = 'Trigger', content = {args.trigger}},
				Cell{name = 'Invulnerable', content = makeArrayLinks(Array.parseCommaSeparatedString(args.invulnerable))},
				Cell{name = 'Introduced', content = {args.introducedDisplay}}
			},
			caller:_damageHealDisplay('damage'),
			caller:_damageHealDisplay('heal')
		)
	end

	return widgets
end

---@param prefix string
function CustomSkill:_calculateDamageHealTotalAndDps(prefix)
	self.args[prefix] = tonumber(self.args[prefix])
	local value = self.args[prefix] or 0
	self.args[prefix .. '_over_time'] = tonumber(self.args[prefix .. '_over_time'])
	local overTime = self.args[prefix .. '_over_time'] or 0
	self.args.duration = tonumber(self.args.duration)
	local duration = self.args.duration or 0

	self.args[prefix .. 'Total'] = value + overTime * duration
	self.args[prefix .. 'Dps'] = duration > 0 and (self.args[prefix .. 'Total'] / duration) or 0
end

---@param prefix string
---@return Widget[]
function CustomSkill:_damageHealDisplay(prefix)
	local value = self.args[prefix]
	local overTime = self.args[prefix .. '_over_time']
	local percentage = tonumber(self.args[prefix .. '_percentage'])
	local total = self.args[prefix .. 'Total']
	local dps = self.args[prefix .. 'Dps']

	local valueText = percentage and (percentage .. '%') or table.concat(Array.append({},
		value,
		overTime and (overTime .. '/s') or nil
	), ' +')

	local textPrefix = mw.getContentLanguage():ucfirst(prefix)
	return {
		Cell{name = textPrefix, content = {valueText}},
		Cell{name = 'Total ' .. textPrefix, content = {total ~= 0 and total or nil}},
		Cell{name = textPrefix .. ' per second', content = {dps ~= 0 and dps ~= overTime and dps or nil}},
	}
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local categories = {args.informationType}
	if self.faction then
		table.insert(categories, self.faction .. ' ' .. args.informationType)
	end

	return categories
end

---@param lpdbData table
---@param args table
---@return table
function CustomSkill:addToLpdb(lpdbData, args)
	lpdbData.information = self.faction
	lpdbData.extradata = {
		deprecated = args.deprecated or '',
		introduced = args.introduced or '',
		subfaction = Array.parseCommaSeparatedString(args.subfaction),
		luminite = tonumber(args.luminite),
		totalluminite = tonumber(args.totalluminite),
		therium = tonumber(args.therium),
		totaltherium = tonumber(args.totaltherium),
		buildtime = tonumber(args.buildtime),
		totalbuildtime = tonumber(args.totalbuildtime),
		rechargetime = tonumber(args.charge_time),
		animus = tonumber(args.animus),
		totalanimus = tonumber(args.totalanimus),
		power = tonumber(args.power),
		totalpower = tonumber(args.totalpower),
		techrequirements = Array.parseCommaSeparatedString(args.tech_requirement),
		buildingrequirements = Array.parseCommaSeparatedString(args.building_requirement),
		targets = Array.parseCommaSeparatedString(args.target),
		casters = self:getAllArgsForBase(args, 'caster'),
		hotkey = args.hotkey,
		hotkey2 = args.hotkey2,
		macrokey = args.macro_key,
		macrokey2 = args.macro_key2,
		energy = tonumber(args.energy),
		duration = tonumber(args.duration),
		from = args.from,
		upgradetarget = Array.parseCommaSeparatedString(args.upgrade_target),
		range = tonumber(args.range),
		radius = tonumber(args.radius),
		cooldown = tonumber(args.cooldown),
		castingtime = tonumber(args.casting_time),
		unlocks = Array.parseCommaSeparatedString(args.unlocks),
		effect = Array.parseCommaSeparatedString(args.effect),
		trigger = args.trigger,
		invulnerable = Array.parseCommaSeparatedString(args.invulnerable),
		damage = args.damage,
		damagepercentage = args.damage_percentage,
		damagetotal = args.damageTotal,
		damagedps = args.damageDps,
		damageovertime = args.damage_over_time,
		health = args.health,
		healthpercentage = args.health_percentage,
		healthtotal = args.healthTotal,
		healthdps = args.healthDps,
		healthovertime = args.health_over_time,
		specialcost = args.special_cost,
		impact = Array.parseCommaSeparatedString(args.impact),
	}

	return lpdbData
end

function CustomSkill:_costDisplay()
	local args = self.args
	local energy = tonumber(args.energy) or 0

	return table.concat(Array.append({},
		CostDisplay.run{
			faction = self.faction,
			luminite = args.luminite,
			luminiteTotal = args.totalluminite,
			therium = args.therium,
			theriumTotal = args.totaltherium,
			animus = args.animus,
			animusTotal = args.totalanimus,
			buildTime = args.buildtime,
			buildTimeTotal = args.totalbuildtime,
			power = args.power,
			powerTotal = args.totalpower,
		},
		energy ~= 0 and (ENERGY_ICON .. '&nbsp;' .. energy) or nil,
		args.special_cost
	), '&nbsp;')
end

---@param hotkey1 string?
---@param hotkey2 string?
---@return string?
function CustomSkill._hotkeys(hotkey1, hotkey2)
	if String.isEmpty(hotkey1) then return end
	if String.isEmpty(hotkey2) then
		return Hotkeys.hotkey(hotkey1)
	end
	return Hotkeys.hotkey2(hotkey1, hotkey2, 'plus')
end

---@param key string
function CustomSkill:_processPatchFromId(key)
	local args = self.args
	local input = Table.extract(args, key)
	if String.isEmpty(input) then return end

	local patches = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::patch]]',
		limit = 5000,
	})

	args[key] = (Array.filter(patches, function(patch)
		return String.endsWith(patch.pagename, '/' .. input)
	end)[1] or {}).pagename
	assert(args[key], 'Invalid patch "' .. input .. '"')

	args[key .. 'Display'] = Page.makeInternalLink(input, args[key])
end

---@param patch string?
---@return Html? -would need to check what warningbox actually returns ... am on phone ...
function CustomSkill._deprecatedWarning(patch)
	if not patch then return end

	return MessageBox.main('ambox', {
		image= ICON_DEPRECATED,
		class='ambox-red',
		text= 'This has been removed from 1v1 with Patch ' .. patch,
	})
end

return CustomSkill
