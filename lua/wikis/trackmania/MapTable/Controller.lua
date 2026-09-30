---
-- @Liquipedia
-- page=Module:MapTable/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')

local MapTableMappers = Lua.import('Module:MapTable/Api/Mappers')
local MapTableStore = Lua.import('Module:MapTable/Api/Store')
local MapTableDisplay = Lua.import('Module:MapTable/Components/Display')
local MapTableParse = Lua.import('Module:MapTable/Lib/Parse')

local MapTableController = {}

---@param frame Frame
---@return Renderable
function MapTableController.run(frame)
	local args = Arguments.getArgs(frame)

	local rows = MapTableParse.readRows(args)
	local mappers = MapTableMappers.resolveMappers(Array.map(rows, MapTableParse.readMappers))
	local links = Array.map(rows, MapTableParse.makeFullLinks)

	local renderedTable = MapTableDisplay.makeTable(rows, mappers, links)

	MapTableStore.storeMaps(rows, mappers, links)

	return renderedTable
end

return MapTableController
