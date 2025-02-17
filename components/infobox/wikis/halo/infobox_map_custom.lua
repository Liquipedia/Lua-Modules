---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class HaloMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Max Players', content = {args.players}},
			Cell{name = 'Game Version', content = {Game.name{game = self.caller.args.game}}, options = {makeLink = true}},
			Cell{name = 'Game Modes', content = self.caller:_getGameMode(args)}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:_getGameMode(args)
	if String.isEmpty(args.mode) and String.isEmpty(args.mode1) then
		return {}
	end

	local modes = self:getAllArgsForBase(args, 'mode')
	local releasedate = args.releasedate

	local modeDisplayTable = {}
	for _, mode in ipairs(modes) do
		local modeIcon = MapModes.get({mode = mode, date = releasedate, size = 15})
		local mapModeDisplay = modeIcon .. ' [[' .. mode .. ']]'
		table.insert(modeDisplayTable, mapModeDisplay)
	end

	return modeDisplayTable
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator)
	if String.isNotEmpty(args.creator2) then
		lpdbData.extradata.creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator2)
	end
	lpdbData.extradata.type = args.type
	lpdbData.extradata.players = args.players
	lpdbData.extradata.game = Game.name{game = args.game}
	lpdbData.extradata.modes = table.concat(self:getAllArgsForBase(args, 'mode'), ',')
	return lpdbData
end

return CustomMap
