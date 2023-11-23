---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Unit/Hero
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local ClassIcon = require('Module:ClassIcon')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local HeroWL = require('Module:HeroWL')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Unit = Lua.import('Module:Infobox/Unit', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Breakdown = Widgets.Breakdown

local CustomHero = {}

local CustomInjector = Class.new(Injector)

local _args

local _pagename = mw.title.getCurrentTitle().text

local _BATTLE_POINTS_ICON = '[[File:Mobile_Legends_BP_icon.png|x16px|Battle Points|link=Battle Point]]'
local _DIAMONDS_ICON = '[[File:Mobile_Legends_Diamond_icon.png|Diamonds|x16px|link=Diamond]]'

local NON_BREAKING_SPACE = '&nbsp;'

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local unit = Unit(frame)
	_args = unit.args
	_args.informationType = 'Hero'

	unit.getWikiCategories = CustomHero.getWikiCategories
	unit.setLpdbData = CustomHero.setLpdbData
	unit.createWidgetInjector = CustomHero.createWidgetInjector

	return unit:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.appendWith(
		widgets,
		Cell{name = 'Specialty', content = {_args.specialty}},
		Cell{name = 'Region', content = {_args.region}},
		Cell{name = 'City', content = {_args.city}},
		Cell{name = 'Attack Type', content = {_args.attacktype}},
		Cell{name = 'Resource Bar', content = {_args.resourcebar}},
		Cell{name = 'Secondary Bar', content = {_args.secondarybar}},
		Cell{name = 'Secondary Attributes', content = {_args.secondaryattributes1}},
		Cell{name = 'Release Date', content = {_args.releasedate}},
		Cell{name = 'Voice Actor(s)', content = CustomHero._voiceActors()}
	)

	local statisticsCells = {
		hp = {order = 1, name = 'Health'},
		hpreg = {order = 2, name = 'Health Regen'},
		mana = {order = 3, name = 'Mana'},
		manareg = {order = 4, name = 'Mana Regen'},
		cdr = {order = 5, name = 'Cooldown Reduction'},
		energy = {order = 6, name = 'Energy'},
		energyreg = {order = 7, name = 'Energy Regen'},
		attacktype = {order = 8, name = 'Attack Type'},
		attackspeed = {order = 9, name = 'Attack Speed'},
		attackrange = {order = 10, name = 'Attack Range'},
		damage = {order = 11, name = 'Attack Damage'},
		ap = {order = 12, name = 'Ability Power'},
		phyatk = {order = 13, name = 'Physical Damage'},
		magatk = {order = 14, name = 'Magical Damage'},
		armor = {order = 15, name = 'Armor'},
		phydef = {order = 16, name = 'Physical Defense'},
		magdef = {order = 17, name = 'Magical Defense'},
		magicresistance = {order = 18, name = 'Magic Resistance'},
		movespeed = {order = 19, name = 'Movement Speed'},
	}
	if Table.any(_args, function(key) return statisticsCells[key] end) then
		table.insert(widgets, Title{name = 'Base Statistics'})
		local statisticsCellsOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
		for key, item in Table.iter.spairs(statisticsCells, statisticsCellsOrder) do
			table.insert(widgets, Cell{name = item.name, content = {_args[key]}})
		end
	end

	table.insert(widgets, Title{name = 'Esports Statistics'})
	table.insert(widgets, Cell{name = 'Win Rate', content = {CustomHero._heroStatsDisplay()}})

	return widgets
end

---@return string
function CustomHero._heroStatsDisplay()
	local stats = mw.text.split(HeroWL.create({hero = _args.heroname or _pagename}), ';')
	local winPercentage = (tonumber(stats[1]) or 0) / ((tonumber(stats[1]) or 0) + (tonumber(stats[2]) or 1))
	winPercentage = Math.round(winPercentage, 4) * 100
	return (stats[1] or 0) .. 'W : ' .. (stats[2] or 0) .. 'L (' .. winPercentage .. '%)'
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'type' then
		local breakDowns = {
			lane = 'Lane',
			primaryrole = 'Primary Role',
			secondaryrole = 'Secondary Role',
		}
		local breakDownContents = {}
		for key, display in pairs(breakDowns) do
			if String.isNotEmpty(_args[key]) then
				local displayText = '<b>'.. display..'</b><br>' .. ClassIcon.display({}, _args[key])
				table.insert(breakDownContents, displayText)
			end
		end
		return {
			Breakdown{classes = {'infobox-center'}, content = breakDownContents},
			Cell{name = 'Real Name', content = {_args.realname}},
		}
	elseif id == 'cost' then
		local costTypes = {
			costbp = _BATTLE_POINTS_ICON,
			costdia = _DIAMONDS_ICON,
		}
		local costs = {}
		for key, icon in pairs(costTypes) do
			if String.isNotEmpty(_args[key]) then
				table.insert(costs, _args[key] .. ' ' .. icon)
			end
		end
		return {
			Cell{name = 'Price', content = {table.concat(costs, '&emsp;&ensp;')}},
		}
	end

	return widgets
end

---@return string[]
function CustomHero._voiceActors()
	local voiceActors = {}

	for voiceActorKey, voiceActor in Table.iter.pairsByPrefix(_args, 'voice') do
		local flag = _args[voiceActorKey .. 'flag']
		if flag then
			voiceActor = Flags.Icon{flag = flag} .. NON_BREAKING_SPACE .. voiceActor
		end
		table.insert(voiceActors, voiceActor)
	end

	return voiceActors
end

---@return WidgetInjector
function CustomHero:createWidgetInjector()
	return CustomInjector()
end

---@param args table
---@return string[]
function CustomHero:getWikiCategories(args)
	local categories = {}
	if Namespace.isMain() then
		categories = {'Heroes'}
		local categoryDefinitions = {'attacktype', 'primaryrole'}
		for _, key in pairs(categoryDefinitions) do
			if String.isNotEmpty(args[key]) then
				table.insert(categories, args[key] .. ' Heroes')
			end
		end
	end
	return categories
end

---@param args table
function CustomHero:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.heroname or _pagename,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			releasedate = args.releasedate,
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.heroname or _pagename), lpdbData)
end

return CustomHero
