---
-- @Liquipedia
-- wiki=mobilelegends
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterWinLoss = require('Module:CharacterWinLoss')
local Class = require('Module:Class')
local CostDisplay = require('Module:CostDisplay')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')

local ClassIcon = Lua.import('Module:ClassIcon', {loadData = true})
local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MobileLegendsHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Hero'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'country' then
		return {
			Cell{name = 'Region', content = {self.caller.args.region}},
			Cell{name = 'City', content = {self.caller.args.city}},
		}
	elseif id == 'role' then
		return {
			Cell{
				name = 'Role',
				content = WidgetUtil.collect(
					self:_toCellContent('primaryrole'),
					self:_toCellContent('secondaryrole')
				)
			},
			Cell{
				name = 'Lane',
				content = {self:_toCellContent('lane')}
			},
		}
	elseif id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_getPriceCell(),
			self.caller:_getCustomCells()
		)
	end

	return widgets
end

---@param key string
---@return Widget?
function CustomInjector:_toCellContent(key)
	local args = self.caller.args
	if String.isEmpty(args[key]) then return end
	local iconData = ClassIcon[args[key]:lower()]
	return Logic.isNotEmpty(iconData) and HtmlWidgets.Fragment{
		children = {
			IconImageWidget{
				imageLight = iconData.icon,
				link = iconData.link,
				size = '15px'
			},
			' ',
			iconData.displayName
		}
	} or nil
end

---@return Widget
function CustomCharacter:_getPriceCell()
	local args = self.args
	return Cell{name = 'Price', content = WidgetUtil.collect(
		String.isNotEmpty(args.costbp) and CostDisplay.run('battle point', args.costbp) or nil,
		String.isNotEmpty(args.costdia) and CostDisplay.run('diamond', args.costdia) or nil,
		String.isNotEmpty(args.costlg) and CostDisplay.run('lucky gem', args.costlg) or nil,
		String.isNotEmpty(args.costticket) and CostDisplay.run('ticket', args.costticket) or nil
	)}
end

---@return Widget[]
function CustomCharacter:_getCustomCells()
	local args = self.args
	local widgets = {}
	Array.appendWith(
		widgets,
		Cell{name = 'Specialty', content = self:_getCharacterSpecialties()},
		Cell{name = 'Attack Type', content = {args.attacktype}},
		Cell{name = 'Resource Bar', content = {args.resourcebar}},
		Cell{name = 'Voice Actor(s)', content = self:_getVoiceActors()}
	)

	local baseStats = {
		{name = 'HP', value = args.hp},
		{name = 'HP Regen', value = args.hpreg},
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
		Array.appendWith(widgets, Title{children = 'Base Statistics'})
	end

	Array.extendWith(widgets, Array.map(baseStats, function(item)
		return Cell{name = item.name, content = {item.value}}
	end))

	local wins, loses = CharacterWinLoss.run(args.name)
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.round(wins * 100 / (wins + loses), 2)

	return Array.append(widgets,
		Title{children = 'Esports Statistics'},
		Cell{name = 'Win Rate', content = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. '%)'}}
	)
end

---@return string[]
function CustomCharacter:_getCharacterSpecialties()
	local args = self.args
	local specialties = {}
	for _, specialty in Table.iter.pairsByPrefix(args, 'specialty', {requireIndex = false}) do
		table.insert(specialties, specialty)
	end
	return specialties
end

---@return string[]
function CustomCharacter:_getVoiceActors()
	local args = self.args
	local voiceActors = {}
	for voiceActorKey, voiceActor in Table.iter.pairsByPrefix(args, 'voice', {requireIndex = false}) do
		local flag = args[voiceActorKey .. 'flag']
		if flag then
			voiceActor = Flags.Icon{flag = flag} .. ' ' .. voiceActor
		end
		table.insert(voiceActors, voiceActor)
	end
	return voiceActors
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.append({},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' Hero') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' Hero') or nil,
		String.isNotEmpty(args.secondaryrole) and (args.secondaryrole .. ' Hero') or nil
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		region = args.region,
		lane = args.lane,
		primaryrole = args.primaryrole,
		secondaryrole = args.secondaryrole,
	}
	return lpdbData
end

return CustomCharacter
