---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Unit/Champion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterWinLoss = require('Module:CharacterWinLoss')
local Class = require('Module:Class')
local DisplayIcon = require('Module:DisplayIcon')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Header = Widgets.Header
local Title = Widgets.Title

---@class LeagueofLegendsUnitInfobox: UnitInfobox
local CustomChampion = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local BLUE_ESSENCE_ICON = '[[File:Blue Essence Icon.png|x20px|Blue Essence|link=Blue Essence]]'
local RIOT_POINTS_ICON = '[[File:RP Points.png|x20px|Riot Points|link=Riot Points]]'

---@param frame Frame
---@return Html
function CustomChampion.run(frame)
	local unit = CustomChampion(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Champion'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'header' then
		return {
			Header{
				name = args.championname,
				subHeader = args.title,
				image = args.image,
				imageDefault = args.default,
				imageDark = args.imagedark or args.imagedarkmode,
				imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			},
		}
	elseif id == 'caption' then
		table.insert(widgets, Center{content = {args.quote}})
	elseif id == 'type' then
		local toBreakDownCell = function(key, title, dataModule)
			if String.isEmpty(args[key]) then return end
			return '<b>' .. title .. '</b><br>' .. DisplayIcon.run{data = 'Module:' .. dataModule, icon = args[key]}
		end

		local breakDownContents = Array.append({},
			toBreakDownCell('region', 'Region', 'RegionIcon'),
			toBreakDownCell('primaryrole', 'Primary Role', 'ClassIcon'),
			toBreakDownCell('secondaryrole', 'Secondary Role', 'ClassIcon')
		)
		return {
			Breakdown{classes = {'infobox-center'}, children = breakDownContents},
			Cell{name = 'Real Name', content = {args.realname}},
		}
	elseif id == 'cost' then
		local cost = Array.append({},
			String.isNotEmpty(args.costbe) and (args.costbe .. ' ' .. BLUE_ESSENCE_ICON) or nil,
			String.isNotEmpty(args.costrp ) and (args.costrp .. ' ' .. RIOT_POINTS_ICON) or nil
		)
		return {
			Cell{name = 'Price', content = {table.concat(cost, '&emsp;&ensp;')}},
		}
	elseif id == 'custom' then
		return self.caller:getCustomCells(widgets)
	end

	return widgets
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

	if Array.any({'hp', 'hplvl', 'hpreg', 'hpreglvl'}, function(key) return String.isNotEmpty(args[key]) end) then
		table.insert(widgets, Title{name = 'Base Statistics'})
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
		Cell{name = 'Movement Speed', content = {args.movespeed}}
	)

	local wins, loses = CharacterWinLoss.run()
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.round(wins * 100 / (wins + loses), 2)

	return Array.append(widgets,
		Title{name = 'Esports Statistics'},
		Cell{name = 'Win Rate', content = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. '%)'}}
	)
end

---@param args table
---@return string[]
function CustomChampion:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.appendWith({'Champions'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' Champions') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' Champions') or nil
	)
end

---@param args table
function CustomChampion:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.championname or self.pagename,
		information = args.primaryrole,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			costbe = args.costbe,
			costrp = args.costrp,
		}
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.championname or self.pagename), lpdbData)
end

return CustomChampion
