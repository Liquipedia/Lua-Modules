---
-- @Liquipedia
-- page=Module:Infobox/Unit/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local Injector = Lua.import('Module:Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ClashroyaleUnitInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
---@class ClashroyaleUnitInfoboxWidgetInjector: WidgetInjector
---@field caller ClashroyaleUnitInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit.args.informationType = 'Card'
	unit:setWidgetInjector(CustomInjector(unit))

	return HtmlWidgets.Fragment{
		unit:createInfobox(),
		CustomUnit._buildDescription(unit.args),
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local makePatch = function(input)
			if not input then return end
			return Link{
				link = 'Patch ' .. input,
				children = {input},
			}
		end
		return {
			Cell{name = 'Ability', children = {args.ability}},
			Cell{name = 'Ability Elixir Cost', children = {args.abilityelixircost}},
			Cell{name = 'Game Mode', children = {args.gamemode}},
			Cell{name = 'Rarity', children = {args.rarity}},
			Cell{name = 'Cycles', children = {args.cycles}},
			Cell{name = 'Arena', children = {args.arena}, options = {makeLink = true}},
			Cell{name = 'Release Date', children = {args.releasedate}},
			Cell{name = 'Deletion Date', children = {args.deletiondate}},
			Cell{name = 'Set', children = {args.set}, options = {makeLink = true}},
			Cell{name = 'Summoned by', children = {args.summonedby}, options = {makeLink = true}},
			Cell{name = 'Introduced', children = {makePatch(args.startversion)}},
			Cell{name = 'Removed since', children = {makePatch(args.endversion)}},
		}
	elseif id == 'cost' then
		return {
			Cell{name = 'Elixir Cost', children = {args.elixir}},
		}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	local postfix = ' Cards'
	return Array.append({},
		'Cards',
		args.set and (args.set .. postfix) or nil,
		args.arena and (args.arena .. postfix) or nil,
		args.cycles and (args.cycles .. postfix) or nil,
		args.rarity and (args.rarity .. postfix) or nil,
		args.type and (args.type .. postfix) or nil,
		args.ability and (args.ability .. '-Cards') or nil,
		args.elixir and (args.elixir .. '-Elixir' .. postfix) or nil,
		args.gamemode and (args.gamemode .. postfix) or nil
	)
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = 'card',
		image = args.image,
		date = args.releasedate,
		extradata = {
			color = args.color,
			cost = args.elixir,
			rarity = args.rarity,
			type = args.type,
			arena = args.arena,
			description = args.caption,
			startversion = args.startversion,
			endversion = args.endversion,
			set = args.set,
			summonedby = args.summonedby,
			chosenfrom = args.chosenfrom,
			artist = args.artist,
			craftable = args.craftable and string.lower(args.craftable) or nil,
		},
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('card_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@return Widget?
function CustomUnit:_buildDescription()
	local args = self.args
	if not Logic.readBool(args['generate description']) then return end

	local lowerCaseIfExist = function(input)
		return input and (' ' .. input:lower()) or nil
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			HtmlWidgets.B{children = self.name},
			' is a',
			lowerCaseIfExist(args.elixir),
			'-Elixir',
			lowerCaseIfExist(args.rarity),
			lowerCaseIfExist(args.type),
			' card that is unlocked from the',
			args.arena and (' ' .. args.arena) or nil,
			' arena.'
		)
	}
end

return CustomUnit
