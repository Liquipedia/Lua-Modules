---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class RematchLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

-- Platform: Platform that the tournament is on
local PLATFORMS = {
	playstation = 'PlayStation',
	xbox = 'Xbox',
	steam = 'Steam',
	cross = 'Cross-Platform',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.platform = PLATFORMS[(league.args.platform or 'steam'):lower():gsub(' ', '')]

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Platform', content = {args.platform}}
		)
	end

	return widgets
end

return CustomLeague
