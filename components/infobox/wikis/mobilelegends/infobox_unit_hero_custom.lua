---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Unit/Hero/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterWinLoss = require('Module:CharacterWinLoss')
local Class = require('Module:Class')
local ClassIcon = require('Module:ClassIcon')
local ClassIconData = require('Module:ClassIcon/Data')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class MobilelegendsHeroInfobox: UnitInfobox
local CustomHero = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local BATTLE_POINTS_ICON = '[[File:Mobile Legends BP icon.png|x16px|Battle Points|link=Battle Points]]'
local DIAMONDS_ICON = '[[File:Mobile Legends Diamond icon.png|16px|Diamonds|link=Diamonds]]'
local LUCKY_GEM_ICON = '[[File:Mobile Legends Lucky Gem.png|x16px|Lucky Gem|link=Lucky Gem]]'
local TICKET_ICON = '[[File:Mobile Legends Ticket icon.png|x16px|Ticket|link=Ticket]]'

local NON_BREAKING_SPACE = '&nbsp;'

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local unit = CustomHero(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Hero'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'caption' then
		table.insert(widgets, Center{content = {args.quote}})
	elseif id == 'type' then
		local toBreakDownCell = function(key, title, dataModule)
			if String.isEmpty(args[key]) then return end
			return '<b>' .. title .. '</b><br>' .. ClassIcon.display({}, args[key])
		end

		local breakDownContents = Array.append({},
			toBreakDownCell('lane', 'Lane', 'ClassIconData'),
			toBreakDownCell('primaryrole', 'Primary Role', 'ClassIconData'),
			toBreakDownCell('secondaryrole', 'Secondary Role', 'ClassIconData')
		)
		return {
			Breakdown{classes = {'infobox-center'}, content = breakDownContents},
		}
	elseif id == 'cost' then
		local cost = Array.append({},
			String.isNotEmpty(args.costbp) and (BATTLE_POINTS_ICON .. ' ' .. args.costbp) or nil,
			String.isNotEmpty(args.costdia) and (DIAMONDS_ICON .. ' ' .. args.costdia) or nil,
			String.isNotEmpty(args.costlg) and (LUCKY_GEM_ICON .. ' ' .. args.costlg) or nil,
			String.isNotEmpty(args.costticket) and (TICKET_ICON .. ' ' .. args.costticket) or nil
		)
		return {
			Cell{name = 'Price', content = {table.concat(cost, '&emsp;&ensp;')}},
		}
	elseif id == 'custom' then
		return self.caller:addCustomCells(widgets)
	end

	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomHero:addCustomCells(widgets)
	local args = self.args
	Array.appendWith(
		widgets,
		Cell{name = 'Specialty', content = {args.specialty}},
		Cell{name = 'Region', content = {args.region}},
		Cell{name = 'City', content = {args.city}},
		Cell{name = 'Attack Type', content = {args.attacktype}},
		Cell{name = 'Resource Bar', content = {args.resourcebar}},
		Cell{name = 'Release Date', content = {args.releasedate}},
		Cell{name = 'Voice Actor(s)', content = CustomHero._voiceActors(args)}
	)
	
	if Array.any({'hp', 'hpreg'}, function(key) return String.isNotEmpty(args[key]) end) then
		table.insert(widgets, Title{name = 'Base Statistics'})
	end

	Array.appendWith(
		widgets,
		Cell{name = 'Health', content = {args.hp}},
		Cell{name = 'Health Regen', content = {args.hpreg}},
		Cell{name = 'Mana', content = {args.mana}},
		Cell{name = 'Mana Regen', content = {args.manareg}},
		Cell{name = 'Energy', content = {args.energy}},
		Cell{name = 'Energy Regen', content = {args.energyreg}},
		Cell{name = 'Physical Attack', content = {args.phyatk}},
		Cell{name = 'Physical Defense', content = {args.phydef}},
		Cell{name = 'Magic Power', content = {args.mp}},
		Cell{name = 'Magic Defense', content = {args.magdef}},
		Cell{name = 'Attack Speed', content = {args.atkspeed}},
		Cell{name = 'Attack Speed Ratio', content = {args.atkspeedratio}},
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
function CustomHero._voiceActors(args)
	local voiceActors = {}

	for voiceActorKey, voiceActor in Table.iter.pairsByPrefix(args, 'voice') do
		local flag = args[voiceActorKey .. 'flag']
		if flag then
			voiceActor = Flags.Icon{flag = flag} .. NON_BREAKING_SPACE .. voiceActor
		end
		table.insert(voiceActors, voiceActor)
	end

	return voiceActors
end

---@param args table
---@return string[]
function CustomHero:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.appendWith({'Heroes'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' Heroes') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' Heroes') or nil
	)
end

---@param args table
function CustomHero:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.heroname or self.pagename,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			releasedate = args.releasedate,
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.heroname or self.pagename), lpdbData)
end

return CustomHero
