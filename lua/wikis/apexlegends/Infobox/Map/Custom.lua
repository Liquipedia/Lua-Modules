---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local TableCell = Widgets.TableCell
local TableRow = Widgets.TableRow
local WidgetTable = Widgets.TableOld

---@class ApexMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class ApexMapInfoboxWidgetInjector: WidgetInjector
---@field caller ApexMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)

	map:setWidgetInjector(CustomInjector(map))
	return map:createInfobox()
end

---@param args table
---@return string[]
function CustomMap:getGameModes(args)
	return {args.gamemode}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game Mode(s)', content = {args.gamemode}},
			Cell{name = 'Played in ALGS', content = {self.caller:_createSpan(args)}}
		)

		if String.isEmpty(args.ring) then return widgets end

		local rows = {self.caller:_createRingTableHeader()}
		Array.forEach(self.caller:getAllArgsForBase(args, 'ring'), function(ringData)
			table.insert(rows, self.caller:_createRingTableRow(ringData))
		end)

		local ringTable = WidgetTable{
			classes = {'fo-nttax-infobox' ,'wiki-bordercolor-light'}, --row alternating bg
			css = {
				['text-align'] = 'center',
				display = 'inline-grid !important',
				['padding-top'] = '0px',
				['padding-bottom'] = '0px',
				['border-top-style'] = 'none',
			},
			children = rows,
		}

		Array.appendWith(widgets,
			Title{children = 'Ring Information'},
			ringTable
		)
	end

	return widgets
end

---@return WidgetTableRow
function CustomMap:_createRingTableHeader()
	return TableRow{css = {['font-weight'] = 'bold'}, children = {
		TableCell{children = {'Ring'}},
		TableCell{children = {'Wait (s)'}},
		TableCell{children = {'Close Time (s)'}},
		TableCell{children = {'Damage per tick'}},
		TableCell{children = {'End Diameter (m)'}},
	}} -- bg needed
end

---@param ringData string
---@return WidgetTableRow
function CustomMap:_createRingTableRow(ringData)
	local cells = {}
	for _, item in ipairs(mw.text.split(ringData, ',')) do
		table.insert(cells, TableCell{children = {item}})
	end
	return TableRow{children = cells}
end

---@param args table
---@return string
function CustomMap:_createSpan(args)
	local sep = ' - '
	local spanEnd = args.spanend
	if String.isEmpty(args.spanstart) then
		sep = ''
		spanEnd = nil
	end

	return table.concat({
			Logic.emptyOr(args.spanstart, '<i><b>Not </b></i>'),
			Logic.emptyOr(spanEnd, '<i><b>Currently</b></i>')
	}, sep)
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.competitive = String.isNotEmpty(args.spanstart) and String.isEmpty(args.spanend)
	return lpdbData
end

return CustomMap
