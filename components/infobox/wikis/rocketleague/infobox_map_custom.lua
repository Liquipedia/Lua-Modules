---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class RocketLeagueMapInfobox: MapInfobox
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
		Array.appendWith(
			widgets,
			Cell{name = 'Layout', content = {args.layout}},
			Cell{name = 'Versions', content = {args.versions}},
			Cell{name = 'Playlists', content = {args.playlists}},
			Cell{name = 'Gamemodes', content = {args.gamemodes}}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	local resolveIfExists = function(value)
		if not value then return end
		return mw.ext.TeamLiquidIntegration.resolve_redirect(value)
	end
	lpdbData.extradata.creator = resolveIfExists(args.creator)
	lpdbData.extradata.creator2 = resolveIfExists(args.creator2)

	return lpdbData
end

return CustomMap
