---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local League = Lua.import('Module:Infobox/League')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local Link = Lua.import('Module:Widget/Basic/Link')

---@class DeltaForceLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local PLATFORMS = {
	pc = 'PC',
	mobile = 'Mobile',
	cross = 'Cross-Platform',
	default = 'Unknown',
}

local MODES = {
	wf = 'Warfare',
	op = 'Operations',
	default = 'Unknown',
}

---@param frame Frame
---@return Widget
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.mode = MODES[(league.args.mode or ''):lower():gsub(' ', '')] or MODES.default
	league.args.platform = PLATFORMS[(league.args.platform or ''):lower():gsub(' ', '')] or PLATFORMS.default

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Mode', children = {args.mode}},
			Cell{name = 'Platform', children = {args.platform}}
		)
	elseif id == 'customcontent' then
		if Logic.isEmpty(args.map1) then return end
		local gameSuffix = Logic.isNotEmpty(args.game) and ('/' .. args.game) or ''
		local maps = self.caller:getAllArgsForBase(args, 'map')
		table.sort(maps)
		local mapDisplays = Array.map(maps, function(map)
			return Link{link = map .. gameSuffix, children = map}
		end)
		Array.appendWith(widgets,
			Title{children = 'Maps'},
			Center{children = Array.interleave(mapDisplays, '&nbsp;• ')}
		)
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			children = self.caller:_createPatchCell(args),
			options = {separator = ' &ndash; '},
		})
	end

	return widgets
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	return {
		Link{link = args.patch},
		Logic.isNotEmpty(args.epatch) and Link{link = args.epatch} or nil,
	}
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		args.mode and (args.mode .. ' Competitions'),
		args.platform and (args.platform .. ' Tournaments'),
	}
end

return CustomLeague
