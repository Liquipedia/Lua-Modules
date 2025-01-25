---
-- @Liquipedia
-- wiki=chess
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class ChessLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	classical = 'Classical',
	blitz = 'Blitz',
	rapid = 'Rapid',
	chess960 = 'Chess960',
	puzzle = 'Puzzle Rush',
	dice = 'Dice Chess',
	various = 'Multiple',
}


local RESTRICTIONS = {
	female = {
		name = 'Female Players Only',
		link = 'Female Tournaments',
		data = 'female',
	},
	amateur = {
		name = 'Amateur Players Only',
		link = 'Amateur Tournaments',
		data = 'amateur',
	},
	junior = {
		name = 'Junior Players Only',
		link = 'Junior Tournaments',
		data = 'junior',
	},
	senior = {
		name = 'Senior Players Only',
		link = 'Senior Tournaments',
		data = 'Senior',
	},
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		Array.appendWith(widgets,
		Cell{name = 'Variant', content = {self.caller:_getGameMode()}},
		Cell{name = 'Restrictions', content = self.caller:createRestrictionsCell(args.restrictions)}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.restrictions) then
		Array.extendWith(categories, Array.map(CustomLeague.getRestrictions(args.restrictions),
				function(res) return res.link end))
	end

	return categories
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)

	Array.forEach(CustomLeague.getRestrictions(args.restrictions),
		function(res) lpdbData.extradata['restriction_' .. res.data] = 1 end)

	return lpdbData
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = self:_getGameMode()
end


---@return string?
function CustomLeague:_getGameMode()
	return MODES[string.lower(self.args.mode or '')] or MODES['classical']
end

---@param restrictions string?
---@return {name: string, data: string, link: string}[]
function CustomLeague.getRestrictions(restrictions)
	if String.isEmpty(restrictions) then
		return {}
	end
	---@cast restrictions -nil

	return Array.map(mw.text.split(restrictions, ','),
		function(restriction) return RESTRICTIONS[mw.text.trim(restriction)] end)
end

---@param restrictions string?
---@return string[]
function CustomLeague:createRestrictionsCell(restrictions)
	local restrictionData = CustomLeague.getRestrictions(restrictions)
	return Array.map(restrictionData, function(res) return self:createLink(res.link, res.name) end)
end

return CustomLeague
