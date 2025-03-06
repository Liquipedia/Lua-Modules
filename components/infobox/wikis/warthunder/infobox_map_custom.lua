-- @Liquipedia
-- wiki=warthunder
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local Class = require('Module:Class')
local Image = require('Module:Image')
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
		local hasTank = String.isNotEmpty(args.tanksize)
		local hasAir = String.isNotEmpty(args.airsize)
		local modes = self.caller:_getGameMode(args)
		local hasModes = #modes > 0

		if hasTank or hasAir or hasModes then
		Array.appendWith(
			widgets,
			Title{children = 'Other Information'},
			Cell{name = 'Tank area size', content = {hasTank and (args.tanksize .. 'km x ' .. args.tanksize .. 'km') or nil}},
			Cell{name = 'Air area size', content = {hasAir and (args.airsize .. 'km x ' .. args.airsize .. 'km') or nil}},
			Cell{name = 'Game Modes', content = hasModes and modes or nil}
		)
	end

	if String.isNotEmpty(args.mapimage) then
		Array.appendWith(
			widgets,
			Title{children = 'Full Map'},
			Widgets.Div{
				classes = {'infobox-image-wrapper'},
				children = {Widgets.Div{
					classes = { 'infobox-image' },
					children = {
						Image.display(args.mapimage, args.mapimage, { size = 600, alignment = 'center' })
					}
				}
			}}

		)
	end
	return widgets
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
		tanksize = tonumber(args.tanksize),
		airsize = tonumber(args.airsize),
		modes = self:getAllArgsForBase(args, 'mode')
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
end

return CustomMap
