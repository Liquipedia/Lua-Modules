---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class NarakaLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	solo = 'Solo[[Category:Solo Mode Tournaments]]',
	trio = 'Trios[[Category:Trios Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
MODES.solos = MODES.solo
MODES.trios = MODES.trio

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
		return {
			Cell{name = 'Game mode', children = {
					self.caller:_getGameMode()
				}
			},
		}
	elseif id == 'customcontent' then
		if args.player_number then
			table.insert(widgets, Title{children = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', children = {args.player_number}})
		elseif args.team_number then
			table.insert(widgets, Title{children = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', children = {args.team_number}})
		end
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number)

	return lpdbData
end

---@return string?
function CustomLeague:_getGameMode()
	if String.isEmpty(self.args.mode) then
		return nil
	end

	return MODES[self.args.mode:lower()] or MODES['default']
end

return CustomLeague
