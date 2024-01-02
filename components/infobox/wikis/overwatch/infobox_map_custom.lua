---
-- @Liquipedia
-- wiki=overwatch
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
local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class OverwatchMapInfobox: MapInfobox
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
	local gameModes = CustomMap._getGameMode(args)

	if id == 'location' then
		return {
			Cell{name = 'Location', content = {
					Flags.Icon{flag = args.location, shouldLink = false} .. '&nbsp;' .. args.location
				}
			},
		}
	end

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = #gameModes == 1 and 'Game Mode' or 'Game Modes', content = gameModes},
			Cell{name = 'Lighting', content = {args.lighting}},
			Cell{name = 'Checkpoints', content = {args.checkpoints}}
		)
	end
	return widgets
end

---@return string[]
function CustomMap._getGameMode(args)
	if String.isEmpty(args.mode) and String.isEmpty(args.mode1) then
		return {}
	end

	local modes = Map:getAllArgsForBase(args, 'mode')
	local releaseDate = args.releasedate

	local modeDisplayTable = {}
	for _, mode in ipairs(modes) do
		local modeIcon = MapModes.get({mode = mode, date = releaseDate, size = 15})
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
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(args, 'mode'), ',')
	return lpdbData
end

return CustomMap
