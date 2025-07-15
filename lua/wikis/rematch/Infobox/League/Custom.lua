---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class RematchLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
---@class RematchLeagueInfoboxWidgetInjector: WidgetInjector
---@field caller RematchLeagueInfobox
local CustomInjector = Class.new(Injector)

-- Platform: Platform that the tournament is on
local PLATFORMS = {
	playstation = 'PlayStation',
	xbox = 'Xbox',
	pc = 'PC',
	cross = 'Cross-Platform',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.platform = PLATFORMS[(self.args.platform or ''):lower():gsub(' ', '')] or PLATFORMS.pc
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	local caller = self.caller

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Platform', content = {caller.data.platform}}
		)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.team_number) then
			Array.appendWith(widgets,
				Title{children = 'Teams'},
				Cell{name = 'Number of teams', content = {args.team_number}}
			)
		elseif String.isNotEmpty(args.player_number) then
			Array.appendWith(widgets,
				Title{children = 'Players'},
				Cell{name = 'Number of players', content = {args.player_number}}
			)
		end
	end
	return widgets
end

return CustomLeague
