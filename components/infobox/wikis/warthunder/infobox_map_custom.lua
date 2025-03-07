-- @Liquipedia
-- wiki=warthunder
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Flags = Lua.import('Module:Flags')
local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class WarThunderMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))
	return map:createInfobox()
end

---@param size string
---@return string|nil
function CustomInjector:_getMapSize(size)
	if String.isNotEmpty(size) then
		return size .. 'km x ' .. size .. 'km'
	end
	return nil
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'location' and String.isNotEmpty(args.country) then
		local locationText = String.isNotEmpty(args.city) and args.city or args.country
		return {
			Cell{name = 'Location', content = {Flags.Icon{flag = args.country, shouldLink = false} .. '&nbsp;' .. locationText}},
		}
	elseif id == 'custom' then
		return Array.append(
				widgets,
				Title{children = 'Other Information'},
				Cell{name = 'Tank area size', content = {self:_getMapSize(args.tanksize)}},
				Cell{name = 'Air area size', content = {self:_getMapSize(args.airsize)}},
				Cell{name = 'Game Modes', content = Logic.nilIfEmpty(self.caller:_getGameMode(args))}
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
	return self:getAllArgsForBase(args, 'mode', { makeLink = true })
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		location = args.country,
	})
	return lpdbData
end

---@param args table
---@return table
function CustomMap:getWikiCategories(args)
	return Array.append({},
		String.isNotEmpty(args.country) and ('Maps located in ' .. args.country) or nil
	)
end

return CustomMap
