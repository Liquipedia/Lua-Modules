---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Unit/Champion
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ChampionWL = require('Module:ChampionWL')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Header = Widgets.Header
local Title = Widgets.Title

---@class LeagueOfLegendsUnitInfobox: UnitInfobox
local CustomChampion = Class.new()

local CustomInjector = Class.new(Injector)

local BLUE_ESSENCE_ICON = '[[File:Blue Essence Icon.png|x20px|Blue Essence|link=Blue Essence]]'
local RIOT_POINTS_ICON = '[[File:RP Points.png|x20px|Riot Points|link=Riot Points]]'

---@param frame Frame
---@return Html
function CustomChampion.run(frame)
	local unit = Unit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Champion'

	unit.getWikiCategories = CustomChampion.getWikiCategories
	unit.setLpdbData = CustomChampion.setLpdbData
	unit.getCustomCells = CustomChampion.getCustomCells

	return unit:createInfobox()
end

---@param args table
---@return string[]
function CustomChampion:getWikiCategories(args)
	if not Namespace.isMain() then
		return {}
	end
	local categories = {'Champions'}
	if not String.isEmpty(args.attacktype) then
		table.insert(categories, args.attacktype .. ' Champions')
	end
	if not String.isEmpty(args.primaryrole) then
		table.insert(categories, args.primaryrole .. ' Champions')
	end
	return categories
end

---@param args table
function CustomChampion:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.championname or self.pagename,
		information = args.primaryrole,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json {
			region = args.region,
			attacktype = args.attacktype,
			primaryrole = args.primaryrole,
			secondaryrole = args.secondaryrole,
			secondarybar = args.secondarybar,
			costbe = args.costbe,
			costrp = args.costrp,
		}
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.championname or self.pagename), lpdbData)
end

---@param widgets Widget[]
---@return Widget[]
function CustomChampion:getCustomCells(widgets)
	local args = self.args
	Array.appendWith(
		widgets,
		Cell{name = 'Attack Type', content = {args.attacktype}},
		Cell{name = 'Resource Bar', content = {args.secondarybar}},
		Cell{name = 'Secondary Bar', content = {args.secondarybar1}},
		Cell{name = 'Secondary Attributes', content = {args.secondaryattributes1}},
		Cell{name = 'Release Date', content = {args.releasedate}}
	)

	if not (
			String.isEmpty(args.hp) and
			String.isEmpty(args.hplvl) and
			String.isEmpty(args.hpreg) and
			String.isEmpty(args.hpreglvl)
		) then
		table.insert(widgets, Title {name = 'Base Statistics'})
	end

	local function bonusPerLevel(start, bonuslvl)
		return bonuslvl and start .. ' (' .. bonuslvl .. ')' or start
	end

	Array.appendWith(
		widgets,
		Cell{name = 'Health', content = {bonusPerLevel(args.hp, args.hplvl)}},
		Cell{name = 'Health Regen', content = {bonusPerLevel(args.hpreg, args.hpreglvl)}},
		Cell{name = 'Courage', content = {args.courage}},
		Cell{name = 'Rage', content = {args.rage}},
		Cell{name = 'Fury', content = {args.fury}},
		Cell{name = 'Heat', content = {args.heat}},
		Cell{name = 'Ferocity', content = {args.ferocity}},
		Cell{name = 'Bloodthirst', content = {args.bloodthirst}},
		Cell{name = 'Mana', content = {bonusPerLevel(args.mana, args.manalvl)}},
		Cell{name = 'Mana Regen', content = {bonusPerLevel(args.manareg, args.manareglvl)}},
		Cell{name = 'Energy', content = {args.energy}},
		Cell{name = 'Energy Regen', content = {args.energyreg}},
		Cell{name = 'Attack Damage', content = {bonusPerLevel(args.damage, args.damagelvl)}},
		Cell{name = 'Attack Speed', content = {bonusPerLevel(args.attackspeed, args.attackspeedlvl)}},
		Cell{name = 'Attack Range', content = {args.attackrange}},
		Cell{name = 'Armor', content = {bonusPerLevel(args.armor, args.armorlvl)}},
		Cell{name = 'Magic Resistance', content = {bonusPerLevel(args.magicresistance, args.magicresistancelvl)}},
		Cell{name = 'Movement Speed', content = {args.movespeed}},
		Title{name = 'Esports Statistics'}
	)

	local stats = ChampionWL.create({champion = args.championname or self.pagename})
	stats = mw.text.split(stats, ';')
	local winPercentage = (tonumber(stats[1]) or 0) / ((tonumber(stats[1]) or 0) + (tonumber(stats[2]) or 1))
	winPercentage = Math.round(winPercentage, 4) * 100
	local statsDisplay = (stats[1] or 0) .. 'W : ' .. (stats[2] or 0) .. 'L (' .. winPercentage .. '%)'
	table.insert(widgets, Cell{name = 'Win Rate', content = {statsDisplay}})

	return widgets
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'header' then
		return {
			Header {
				name = args.championname,
				subHeader = args.title,
				image = args.image,
				imageDefault = args.default,
				imageDark = args.imagedark or args.imagedarkmode,
				imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			},
		}
	elseif id == 'caption' then
		table.insert(widgets, Center {content = {args.quote}})
	elseif id == 'type' then
		local breakDownContents = {}
		local region = args.region
		if not String.isEmpty(region) then
			region = '<b>Region</b><br>' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Region icon', {region}, '')
			table.insert(breakDownContents, region)
		end
		local primaryRole = args.primaryrole
		if not String.isEmpty(primaryRole) then
			primaryRole = '<b>Primary Role</b><br>' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Class icon', {primaryRole}, '')
			table.insert(breakDownContents, primaryRole)
		end
		local secondaryRole = args.secondaryrole
		if not String.isEmpty(secondaryRole) then
			secondaryRole = '<b>Secondary Role</b><br>' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Class icon', {secondaryRole},
					'')
			table.insert(breakDownContents, secondaryRole)
		end
		return {
			Breakdown{classes = {'infobox-center'}, content = breakDownContents},
			Cell{name = 'Real Name', content = {args.realname}},
		}
	elseif id == 'cost' then
		local cost = ''
		if not String.isEmpty(args.costbe) then
			cost = cost .. args.costbe .. ' ' .. BLUE_ESSENCE_ICON
		end
		if not String.isEmpty(args.costrp) then
			if cost ~= '' then
				cost = cost .. '&emsp;&ensp;'
			end
			cost = cost .. args.costrp .. ' ' .. RIOT_POINTS_ICON
		end
		return {
			Cell{name = 'Price', content = {cost}},
		}
	elseif id == 'custom' then
		self.caller:getCustomCells(widgets)
	end

	return widgets
end

return CustomChampion
