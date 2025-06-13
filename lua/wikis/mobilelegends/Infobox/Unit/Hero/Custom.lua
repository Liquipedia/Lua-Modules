---
-- @Liquipedia
-- page=Module:Infobox/Unit/Hero/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterWinLoss = require('Module:CharacterWinLoss')
local Class = require('Module:Class')
local ClassIcon = require('Module:ClassIcon')
local Flags = require('Module:Flags')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class MobilelegendsHeroInfobox: UnitInfobox
local CustomHero = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local ICON_DATA = {
	battlePoints = {icon = 'Mobile Legends BP icon.png', link = '', caption = 'Battle Points'},
	diamonds = {icon = 'Mobile Legends Diamond icon.png', link = '', caption = 'Diamonds'},
	luckyGem = {icon = 'Mobile Legends Lucky Gem.png', link = '', caption = 'Lucky Gem'},
	ticket = {icon = 'Mobile Legends Ticket icon.png', link = '', caption = 'Ticket'}
}

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
		table.insert(widgets, Center{children = {args.quote}})
	elseif id == 'type' then
		local toBreakDownCell = function(key, title)
			if String.isEmpty(args[key]) then return end
			return '<b>' .. title .. '</b><br>' .. ClassIcon.display({}, args[key])
		end

		local breakDownContents = Array.append({},
			toBreakDownCell('lane', 'Lane'),
			toBreakDownCell('primaryrole', 'Primary Role'),
			toBreakDownCell('secondaryrole', 'Secondary Role')
		)
		return {
			Breakdown{classes = {'infobox-center'}, children = breakDownContents},
		}
	elseif id == 'cost' then
		local cost = Array.append({},
			CustomHero.getIcon('battlePoints', args.costbp),
			CustomHero.getIcon('diamonds', args.costdia),
			CustomHero.getIcon('luckyGem', args.costlg),
			CustomHero.getIcon('ticket', args.costticket)
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
	local baseStats = {
		{name = 'Health', value = args.hp},
		{name = 'Health Regen', value = args.hpreg},
		{name = 'Mana', value = args.mana},
		{name = 'Mana Regen', value = args.manareg},
		{name = 'Energy', value = args.energy},
		{name = 'Energy Regen', value = args.energyreg},
		{name = 'Physical Attack', value = args.phyatk},
		{name = 'Physical Defense', value = args.phydef},
		{name = 'Magic Power', value = args.mp},
		{name = 'Magic Defense', value = args.magdef},
		{name = 'Attack Speed', value = args.atkspeed},
		{name = 'Attack Speed Ratio', value = args.atkspeedratio},
		{name = 'Movement Speed', value = args.movespeed}
	}

	if Array.any(baseStats, function(item) return Logic.isNotEmpty(item.value) end) then
		table.insert(widgets, Title{children = 'Base Statistics'})
	end

	Array.extendWith(widgets, Array.map(baseStats, function(item)
		return Cell{name = item.name, content = {item.value}}
	end))
	local wins, loses = CharacterWinLoss.run()
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.round(wins * 100 / (wins + loses), 2)

	return Array.append(widgets,
		Title{children = 'Esports Statistics'},
		Cell{name = 'Win Rate', content = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. '%)'}}
	)
end

---@param iconKey string
---@param value string|number?
---@return string?
function CustomHero.getIcon(iconKey, value)
	if Logic.isEmpty(value) then return nil end

	local iconData = ICON_DATA[iconKey]
	assert(iconData, 'Invalid iconKey "' .. iconKey .. '"')

	return Image.display(iconData.icon, iconData.iconDark, {
			size = '16x16px',
			link = iconData.link,
			caption = iconData.caption
		}
	) .. ' ' .. value
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
			lane = args.lane,
			primaryrole = args.primaryrole,
			secondaryrole = args.secondaryrole,
			region = args.region,
			releasedate = args.releasedate,
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.heroname or self.pagename), lpdbData)
end

return CustomHero
