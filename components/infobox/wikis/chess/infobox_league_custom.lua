---
-- @Liquipedia
-- wiki=chess
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class ChessLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

-- Mode: Time controls.
local MODES = {
	classical = 'Classical',
	blitz = 'Blitz',
	rapid = 'Rapid',
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
		data = 'senior',
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
	local caller = self.caller
	local args = caller.args
	if id == 'custom' then
		table.insert(
			widgets,
			Cell{name = 'Restrictions', content = caller:createRestrictionsCell(args.restrictions)}
		)
	elseif id == 'gamesettings' then
		local isVariant = caller.data.game ~= Game.toIdentifier()
		local modes = mw.text.split(caller.data.mode, ',')
		Array.appendWith(widgets,
			Cell{name = 'Time Control' .. (#modes > 1 and 's' or ''), content = modes},
			isVariant and Cell{name = 'Variant', content = {Game.name{game = caller.data.game}}} or nil
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return Array.map(CustomLeague.getRestrictions(args.restrictions), Operator.property('link'))
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
	local modes = {}
	local modePairs = Table.iter.pairsByPrefix(self.args, 'mode', {requireIndex = false})
	for _, mode, _ in modePairs do
		table.insert(modes, MODES[string.lower(mode)])
	end
	if Table.isEmpty(modes) then
		modes = {MODES.classical}
	end
	self.data.mode = table.concat(modes, ',')
end

---@param restrictions string?
---@return {name: string, data: string, link: string}[]
function CustomLeague.getRestrictions(restrictions)
	return Array.map(Array.parseCommaSeparatedString(restrictions),
		function(restriction) return RESTRICTIONS[restriction] end)
end

---@param restrictions string?
---@return string[]
function CustomLeague:createRestrictionsCell(restrictions)
	local restrictionData = CustomLeague.getRestrictions(restrictions)
	return Array.map(restrictionData, function(res) return self:createLink(res.link, res.name) end)
end

return CustomLeague
