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
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class DeadlockLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
---@class DeadlockLeagueInfoboxWidgetInjector: WidgetInjector
---@field caller DeadlockLeagueInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Widget
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

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Number of teams', children = {args.team_number}},
			Cell{name = 'Number of players', children = {args.player_number}},
			Cell{name = 'Version', children = self.caller:_createPatchCell(args)}
		)
	end

	return widgets
end

---@param args table
---@return Widget[]?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return
	end
	return WidgetUtil.collect(
		Link{link = 'Patch_' .. args.patch, children = {args.patch}},
		String.isNotEmpty(args.epatch) and args.patch ~= args.epatch and {
			' &ndash; ',
			Link{link = 'Patch_' .. args.epatch, children = {args.epatch}},
		} or nil
	)
end

return CustomLeague
