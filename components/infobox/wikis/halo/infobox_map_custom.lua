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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class HaloMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

local GAME = mw.loadData('Module:GameVersion')

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Max Players', content = {args.players}},
			Cell{name = 'Game Version', content = {self.caller:getGameVersion(args)}, options = {makeLink = true}},
			Cell{name = 'Game Modes', content = self.caller:getGameMode(args)}
		)
	end
	return widgets
end

--@return string[]
function CustomMap:getGameVersion(args)
	local game = string.lower(args.game or '')
	game = GAME[game]
	return game
end

---@return string[]
function CustomMap:getGameMode(args)
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
	lpdbData.extradata.game = args.game
	lpdbData.extradata.modes = table.concat(self:getAllArgsForBase(args, 'mode'), ',')
	return lpdbData
end

return CustomMap
