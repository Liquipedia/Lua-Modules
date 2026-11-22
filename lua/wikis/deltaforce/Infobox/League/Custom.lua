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

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local Link = Lua.import('Module:Widget/Basic/Link')

---@class DeltaForceLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)

---@class DeltaForceLeagueInfoboxInjector
---@class DeltaForceLeagueInfoboxWidgetInjector: WidgetInjector
---@field caller DeltaForceLeagueInfobox
---@operator call(DeltaForceLeagueInfobox): DeltaForceLeagueInfoboxWidgetInjector
local CustomInjector = Class.new(Injector)

local PLATFORMS = {
	pc = 'PC',
	mobile = 'Mobile',
	default = 'Unknown',
}

local MODES = {
	warfare = 'Warfare',
	operations = 'Operations',
	detonation = 'Detonation',
	default = 'Unknown',
}
MODES.wf = MODES.warfare
MODES.op = MODES.operations

---@param frame Frame
---@return VNode
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))
	
	return league:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]?
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Mode', children = {args.mode}},
			Cell{name = 'Platform', children = {args.platform}}
		)
	elseif id == 'customcontent' then
		local maps = self.caller:getAllArgsForBase(args, 'map')
		if Logic.isEmpty(maps) then return end
		table.sort(maps)
		local mapDisplays = Array.map(maps, function(map)
			return Link{link = map, children = map}
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
function CustomLeague:customParseArguments(args)
	-- Normalize Mode input
	args.mode = args.mode and MODES[string.lower(args.mode):gsub('s$', '')] or MODES.default
	self.data.mode = string.lower(args.mode)

	-- Normalize Platform input
	args.platform = args.platform and PLATFORMS[string.lower(args.platform):gsub('s$', '')] or PLATFORMS.default
	self.data.mode = string.lower(args.platform)

end

---@param args table
---@return Renderable[]?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	return {
		Link{link = 'Patch ' .. args.patch},
		Logic.isNotEmpty(args.endpatch) and Link{link = 'Patch ' .. args.endpatch} or nil,
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
