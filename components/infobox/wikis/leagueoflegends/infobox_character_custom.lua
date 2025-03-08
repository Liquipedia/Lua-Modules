---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterWinLoss = require('Module:CharacterWinLoss')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

local BLUE_ESSENCE_ICON = IconImageWidget{
	imageLight = 'Blue Essence Icon.png',
	link = 'Blue Essence'
}
local RIOT_POINTS_ICON = IconImageWidget{
	imageLight = 'RP Points.png',
	link = 'Riot Points'
}

---@class LeagueofLegendsChampionInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Champion'

	local args = character.args
	args.caption = args.quote


	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'overview' then
		local breakDownContents = WidgetUtil.collect(
			self:_toBreakDownCell('region', 'Region', 'RegionIcon'),
			self:_toBreakDownCell('primaryrole', 'Primary Role', 'ClassIcon'),
			self:_toBreakDownCell('secondaryrole', 'Secondary Role', 'ClassIcon')
		)
		return { Breakdown{classes = {'infobox-center'}, children = breakDownContents} }
	elseif id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_getPriceCell(),
			self.caller:_getCustomCells()
		)
	end

	return widgets
end

---@param key string
---@param title string
---@param dataModule string
---@return Widget?
function CustomInjector:_toBreakDownCell(key, title, dataModule)
	local args = self.caller.args
	if String.isEmpty(args[key]) then return end
	local data = Lua.requireIfExists('Module:' .. dataModule, { loadData = true })
	if Logic.isEmpty(data) then return end
	local iconData = data[args[key]:lower()]
	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.B{
				children = { title }
			},
			HtmlWidgets.Br{},
			IconImageWidget{
				imageLight = iconData.icon,
				size = '50px',
				link = iconData.link
			}
		}
	}
end

---@return Widget
function CustomCharacter:_getPriceCell()
	local args = self.args
	local costContent = WidgetUtil.collect(
		String.isNotEmpty(args.costbe) and HtmlWidgets.Fragment{
			children = { args.costbe, ' ', BLUE_ESSENCE_ICON }
		} or nil,
		String.isNotEmpty(args.costrp) and HtmlWidgets.Fragment{
			children = { args.costrp, ' ', RIOT_POINTS_ICON }
		} or nil
	)
	return Cell{ name = 'Price', content = costContent }
end

---@return Widget[]
function CustomCharacter:_getCustomCells()
	local args = self.args
	local widgets = {
		Cell{name = 'Attack Type', content = {args.attacktype}},
		Cell{name = 'Resource Bar', content = {args.secondarybar}},
		Cell{name = 'Secondary Bar', content = {args.secondarybar1}},
		Cell{name = 'Secondary Attributes', content = {args.secondaryattributes1}},
	}

	if Array.any({'hp', 'hplvl', 'hpreg', 'hpreglvl'}, function(key) return String.isNotEmpty(args[key]) end) then
		Array.appendWith(widgets, Title{children = 'Base Statistics'})
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
		Title{children = 'Esports Statistics'},
		Cell{name = 'Win Rate', content = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. '%)'}}
	)
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.appendWith({'Champions'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' Champions') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' Champions') or nil
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.information = args.primaryrole
	lpdbData.extradata = {
		region = args.region,
		costbe = args.costbe,
		costrp = args.costrp,
	}
	return lpdbData
end

return CustomCharacter
