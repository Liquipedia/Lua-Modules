---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local WidgetTable = Lua.import('Module:Widget/Table2/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class ApexMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class ApexMapInfoboxWidgetInjector: WidgetInjector
---@field caller ApexMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
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
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Game Mode(s)', children = {args.gamemode}},
			Cell{name = 'Played in ALGS', children = {self.caller:_playedInAlgsDisplay(args)}}
		)

		if String.isEmpty(args.ring) then return widgets end

		local rows = Array.extend(
			{self.caller:_createRingTableHeader()},
			Array.map(self.caller:getAllArgsForBase(args, 'ring'), function(ringData)
				return self.caller:_createRingTableRow(ringData)
			end)
		)

		local ringTable = WidgetTable.Table{
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

---@return Renderable
function CustomMap:_createRingTableHeader()
	return WidgetTable.Row{children = {
		WidgetTable.CellHeader{children = {'Ring'}},
		WidgetTable.CellHeader{children = {'Wait (s)'}},
		WidgetTable.CellHeader{children = {'Close Time (s)'}},
		WidgetTable.CellHeader{children = {'Damage per tick'}},
		WidgetTable.CellHeader{children = {'End Diameter (m)'}},
	}}
end

---@param ringData string
---@return Renderable
function CustomMap:_createRingTableRow(ringData)
	return WidgetTable.Row{
		children = Array.map(Array.parseCommaSeparatedString(ringData), function(item)
			return WidgetTable.Cell{children = {item}}
		end)
	}
end

---@param args table
---@return string
function CustomMap:_playedInAlgsDisplay(args)
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
