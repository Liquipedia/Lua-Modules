---
-- @Liquipedia
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Strategy = Lua.import('Module:Infobox/Strategy')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header

---@class Starcraft2StrategyInfobox: StrategyInfobox
local CustomStrategy = Class.new(Strategy)

local RACE_MATCHUPS = {
	'ZvZ', 'ZvP', 'ZvT',
	'TvZ', 'TvP', 'TvT',
	'PvZ', 'PvP', 'PvT',
}

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomStrategy.run(frame)
	local customStrategy = CustomStrategy(frame)
	customStrategy
		:setWidgetInjector(CustomInjector(customStrategy))
		:setWikiCategories()

	return customStrategy:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'header' then
		return {Header{name = self.caller:_getNameDisplay(), image = args.image}}
	elseif id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Matchups', content = {args.matchups or 'All'}},
			Cell{name = 'Type', content = {args.type or 'Opening'}},
			Cell{name = 'Popularized by', content = {args.popularized}, options = {makeLink = true}},
			Cell{name = 'Converted Form', content = {args.convert}},
			Cell{name = 'TL-Article', content = {self.caller:_getTLarticle(args.tlarticle)}}
		)
	end
	return widgets
end

---@return string
function CustomStrategy:_getNameDisplay()
	local race = Faction.Icon{size = 'large', faction = self.args.race} or ''
	return race .. (self.args.name or mw.title.getCurrentTitle().text)
end

---@param tlarticle string?
---@return string?
function CustomStrategy:_getTLarticle(tlarticle)
	if not String.isEmpty(tlarticle) then
		return '[[File:TL Strategy presents.png|left|95px]] ' ..
			'This article is a spotlighted, peer-reviewed guide by TL Strategy. ['
			.. tlarticle .. ' Link]'
	end
end

---@return self
function CustomStrategy:setWikiCategories()
	if not Namespace.isMain() then
		return self
	end

	self:categories(unpack(self:_getCategories()))

	return self
end

---@return string[]
function CustomStrategy:_getCategories()
	local race = Faction.toName(Faction.read(self.args.race))

	if not race then return {} end

	local categoryType = self.args.informationType
	if categoryType == 'Strategy' then
		categoryType = 'Build Order'
	end

	local categories = {race .. ' ' .. categoryType .. 's'}

	local matchups = self.args.matchups
	if String.isEmpty(matchups) or categoryType ~= 'Build Order' then
		return categories
	end
	---@cast matchups -nil

	for _, raceMatchupItem in ipairs(RACE_MATCHUPS) do
		if String.contains(matchups, raceMatchupItem) then
			table.insert(categories, raceMatchupItem .. ' Builds')
		end
	end

	return categories
end

return CustomStrategy
