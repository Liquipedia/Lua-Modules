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

local Injector = Lua.import('Module:Infobox/Widget/Injector', { requireDevIfEnabled = true })
local Unit = Lua.import('Module:Infobox/Unit', { requireDevIfEnabled = true })

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Header = Widgets.Header
local Title = Widgets.Title

local CustomChampion = Class.new()

local CustomInjector = Class.new(Injector)

local _args

local _pagename = mw.title.getCurrentTitle().text
local _frame

local BLUE_ESSENCE_ICON = '[[File:Blue Essence Icon.png|x20px|Blue Essence|link=Blue Essence]]'
local RIOT_POINTS_ICON = '[[File:RP Points.png|x20px|Riot Points|link=Riot Points]]'

---@param frame Frame
---@return Html
function CustomChampion.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	_frame = frame
	_args.informationType = 'Champion'

	unit.getWikiCategories = CustomChampion.getWikiCategories
	unit.setLpdbData = CustomChampion.setLpdbData
	unit.createWidgetInjector = CustomChampion.createWidgetInjector

	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Cell { name = 'Attack Type', content = { _args.attacktype } },
		Cell { name = 'Resource Bar', content = { _args.secondarybar } },
		Cell { name = 'Secondary Bar', content = { _args.secondarybar1 } },
		Cell { name = 'Secondary Attributes', content = { _args.secondaryattributes1 } },
		Cell { name = 'Release Date', content = { _args.releasedate } }
	)

	if not (
			String.isEmpty(_args.hp) and
			String.isEmpty(_args.hplvl) and
			String.isEmpty(_args.hpreg) and
			String.isEmpty(_args.hpreglvl)
		) then
		table.insert(widgets, Title { name = 'Base Statistics' })
	end

	local function bonusPerLevel(start, bonuslvl)
		return bonuslvl and start .. ' (' .. bonuslvl .. ')' or start
	end

	Array.appendWith(
		widgets,
		Cell { name = 'Health', content = { bonusPerLevel(_args.hp, _args.hplvl) } },
		Cell { name = 'Health Regen', content = { bonusPerLevel(_args.hpreg, _args.hpreglvl) } },
		Cell { name = 'Courage', content = { _args.courage } },
		Cell { name = 'Rage', content = { _args.rage } },
		Cell { name = 'Fury', content = { _args.fury } },
		Cell { name = 'Heat', content = { _args.heat } },
		Cell { name = 'Ferocity', content = { _args.ferocity } },
		Cell { name = 'Bloodthirst', content = { _args.bloodthirst } },
		Cell { name = 'Mana', content = { bonusPerLevel(_args.mana, _args.manalvl) } },
		Cell { name = 'Mana Regen', content = { bonusPerLevel(_args.manareg, _args.manareglvl) } },
		Cell { name = 'Energy', content = { _args.energy } },
		Cell { name = 'Energy Regen', content = { _args.energyreg } },
		Cell { name = 'Attack Damage', content = { bonusPerLevel(_args.damage, _args.damagelvl) } },
		Cell { name = 'Attack Speed', content = { bonusPerLevel(_args.attackspeed, _args.attackspeedlvl) } },
		Cell { name = 'Attack Range', content = { _args.attackrange } },
		Cell { name = 'Armor', content = { bonusPerLevel(_args.armor, _args.armorlvl) } },
		Cell { name = 'Magic Resistance', content = { bonusPerLevel(_args.magicresistance, _args.magicresistancelvl) } },
		Cell { name = 'Movement Speed', content = { _args.movespeed } },
		Title { name = 'Esports Statistics' }
	)

	local stats = ChampionWL.create({ champion = _args.championname or _pagename })
	stats = mw.text.split(stats, ';')
	local winPercentage = (tonumber(stats[1]) or 0) / ((tonumber(stats[1]) or 0) + (tonumber(stats[2]) or 1))
	winPercentage = Math.round(winPercentage, 4) * 100
	local statsDisplay = (stats[1] or 0) .. 'W : ' .. (stats[2] or 0) .. 'L (' .. winPercentage .. '%)'
	table.insert(widgets, Cell { name = 'Win Rate', content = { statsDisplay } })

	return widgets
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'header' then
		return {
			Header {
				name = _args.championname,
				subHeader = _args.title,
				image = _args.image,
				imageDefault = _args.default,
				imageDark = _args.imagedark or _args.imagedarkmode,
				imageDefaultDark = _args.defaultdark or _args.defaultdarkmode,
			},
		}
	elseif id == 'caption' then
		table.insert(widgets, Center { content = { _args.quote } })
	elseif id == 'type' then
		local breakDownContents = {}
		local region = _args.region
		if not String.isEmpty(region) then
			region = '<b>Region</b><br>' .. Template.safeExpand(_frame, 'Region icon', { region }, '')
			table.insert(breakDownContents, region)
		end
		local primaryRole = _args.primaryrole
		if not String.isEmpty(primaryRole) then
			primaryRole = '<b>Primary Role</b><br>' .. Template.safeExpand(_frame, 'Class icon', { primaryRole }, '')
			table.insert(breakDownContents, primaryRole)
		end
		local secondaryRole = _args.secondaryrole
		if not String.isEmpty(secondaryRole) then
			secondaryRole = '<b>Secondary Role</b><br>' .. Template.safeExpand(_frame, 'Class icon', { secondaryRole },
				'')
			table.insert(breakDownContents, secondaryRole)
		end
		return {
			Breakdown { classes = { 'infobox-center' }, content = breakDownContents },
			Cell { name = 'Real Name', content = { _args.realname } },
		}
	elseif id == 'cost' then
		local cost = ''
		if not String.isEmpty(_args.costbe) then
			cost = cost .. _args.costbe .. ' ' .. BLUE_ESSENCE_ICON
		end
		if not String.isEmpty(_args.costrp) then
			if cost ~= '' then
				cost = cost .. '&emsp;&ensp;'
			end
			cost = cost .. _args.costrp .. ' ' .. RIOT_POINTS_ICON
		end
		return {
			Cell { name = 'Price', content = { cost } },
		}
	end

	return widgets
end

---@return WidgetInjector
function CustomChampion:createWidgetInjector()
	return CustomInjector()
end

---@param args table
---@return string[]
function CustomChampion:getWikiCategories(args)
	local categories = {}
	if Namespace.isMain() then
		categories = { 'Champions' }
		if not String.isEmpty(args.attacktype) then
			table.insert(categories, args.attacktype .. ' Champions')
		end
		if not String.isEmpty(args.primaryrole) then
			table.insert(categories, args.primaryrole .. ' Champions')
		end
	end
	return categories
end

---@param args table
function CustomChampion:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.championname or _pagename,
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
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.championname or _pagename), lpdbData)
end

return CustomChampion
