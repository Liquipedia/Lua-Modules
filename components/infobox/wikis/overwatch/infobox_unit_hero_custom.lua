---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/Unit/Hero/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Unit = Lua.import('Module:Infobox/Unit')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Breakdown = Widgets.Breakdown

---@class OverwatchHeroInfobox: UnitInfobox
local CustomUnit = Class.new(Unit)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnit.run(frame)
	local unit = CustomUnit(frame)
	unit:setWidgetInjector(CustomInjector(unit))
	unit.args.informationType = 'Hero'
	return unit:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
		widgets,
			Cell{name = 'Role', content = {args.role}},
			Cell{name = 'Real Name', content = {args.realname}},
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Relations', content = {args.relations}},
			Cell{name = 'Occupation', content = {args.occupation}},
			Cell{name = 'Base of Operations', content = {args.baseofoperations}},
			Cell{name = 'Affiliation', content = {args.affiliation}},
			Cell{name = 'Release Date', content = {args.releasedate}},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactor}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomUnit:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	local categories = {'Heroes'}
	if String.isEmpty(args.role) then
		return categories
	end
	return Array.append(categories, args.role .. ' Heroes')
end

---@param args table
function CustomUnit:setLpdbData(args)
	local lpdbData = {
		type = 'hero',
		name = args.heroname or self.pagename,
		image = args.image,
		date = args.releasedate,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			role = args.role,
		})
	}
	mw.ext.LiquipediaDB.lpdb_datapoint('hero_' .. (args.heroname or self.pagename), lpdbData)
end

return CustomUnit
