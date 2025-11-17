---
-- @Liquipedia
-- page=Module:Infobox/Unit/God/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterWinLoss = Lua.import('Module:CharacterWinLoss')
local Class = Lua.import('Module:Class')
local DisplayIcon = Lua.import('Module:DisplayIcon')
local Math = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Header = Widgets.Header
local Title = Widgets.Title

---@class SmiteUnitInfobox: UnitInfobox
local CustomGod = Class.new(Unit)
local CustomInjector = Class.new(Injector)

local FAVOR_ICON = '[[File:Smite Currency Favor.png|x20px|Favor|link=Favor]]'
local GEMS_ICON = '[[File:Smite Currency Gems.png|x20px|Gems|link=Gems]]'

---@param frame Frame
---@return Html
function CustomGod.run(frame)
	local unit = CustomGod(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'God'

	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'header' then
		return {
			Header {
				name = args.godname,
				subHeader = args.title,
				image = args.image,
				imageDefault = args.default,
				imageDark = args.imagedark or args.imagedarkmode,
				imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			},
		}
	elseif id == 'caption' then
		table.insert(widgets, Center{children = {args.quote}})
	elseif id == 'type' then
		local toBreakDownCell = function(key, title, dataModule)
				if String.isEmpty(args[key]) then return end
				return '<b>' .. title .. '</b><br>' .. DisplayIcon.run{data = 'Module:' .. dataModule, icon = args[key]}
			end

			local breakDownContents = Array.append({},
				toBreakDownCell('pantheon', 'Pantheon', 'PantheonIcon'),
				toBreakDownCell('class', 'Class', 'ClassIcon'),
				toBreakDownCell('powertype', 'Power Type', 'PowerTypeIcon')
			)
		return {
			Breakdown{classes = {'infobox-center'}, children = breakDownContents},
			Cell{name = 'Real Name', children = {args.realname}},
		}
	elseif id == 'cost' then
		local cost = Array.append({},
				String.isNotEmpty(args.costfavor) and (args.costfavor .. ' ' .. FAVOR_ICON) or nil,
				String.isNotEmpty(args.costgems ) and (args.costgems .. ' ' .. GEMS_ICON) or nil
			)
			return {
				Cell{name = 'Price', children = {table.concat(cost, '&emsp;&ensp;')}},
			}
	elseif id == 'custom' then
		return self.caller:getCustomCells(widgets)
	end

	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomGod:getCustomCells(widgets)
	local args = self.args
	Array.appendWith(
		widgets,
		Cell{name = 'Attack Type', children = {args.attacktype}},
		Cell{name = 'Difficulty', children = {args.difficulty}},
		Cell{name = 'Release Date', children = {args.releasedate}}
	)

	if Array.any({'hp', 'hplvl', 'hp5', 'hp5lvl'}, function(key) return String.isNotEmpty(args[key]) end) then
		table.insert(widgets, Title {name = 'Base Statistics'})
	end

	local function bonusPerLevel(start, bonuslvl)
		return bonuslvl and start .. ' (' .. bonuslvl .. ')' or start
	end

	Array.appendWith(
		widgets,
		Cell{name = 'Health', children = {bonusPerLevel(args.hp, args.hplvl)}},
		Cell{name = 'Health Regen (HP5)', children = {bonusPerLevel(args.hp5, args.hp5lvl)}},
		Cell{name = 'Mana', children = {bonusPerLevel(args.mana, args.manalvl)}},
		Cell{name = 'Mana Regen (MP5)', children = {bonusPerLevel(args.mp5, args.mp5lvl)}},
		Cell{name = 'Movement Speed', children = {bonusPerLevel(args.speed, args.speedlvl)}},
		Cell{name = 'Attack Range', children = {bonusPerLevel(args.attackrange, args.attackrangelvl)}},
		Cell{name = 'Attack Speed', children = {bonusPerLevel(args.attackspeed, args.attackspeedlvl)}},
		Cell{name = 'Attack Damage', children = {bonusPerLevel(args.damage, args.damagelvl), args.damagebonus}},
		Cell{name = 'Progression', children = {args.progression}},
		Title{children = 'Protections'},
		Cell{name = 'Physical', children = {bonusPerLevel(args.physical, args.physicallvl)}},
		Cell{name = 'Magical', children = {bonusPerLevel(args.magical, args.magicallvl)}}
	)

	local wins, loses = CharacterWinLoss.run()
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.round(wins * 100 / (wins + loses), 2)

	return Array.append(widgets,
		Title{children = 'Esports Statistics'},
		Cell{name = 'Win Rate', children = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. '%)'}}
	)
end

---@param args table
---@return string[]
function CustomGod:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	return Array.appendWith({'Gods'},
		String.isNotEmpty(args.attacktype) and (args.attacktype .. ' Gods') or nil,
		String.isNotEmpty(args.primaryrole) and (args.primaryrole .. ' Gods') or nil
	)
end

---@param args table
function CustomGod:setLpdbData(args)
	local lpdbData = {
		type = 'gods',
		name = args.godname or self.pagename,
		information = args.primaryrole,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json {
			pantheon = args.pantheon,
			attacktype = args.attacktype,
			primaryrole = args.primaryrole,
			secondaryrole = args.secondaryrole,
			secondarybar = args.secondarybar,
			costfavor = args.costfavor,
			costgems = args.costgems,
		}
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('god_' .. (args.godname or self.pagename), lpdbData)
end



return CustomGod
