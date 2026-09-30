---
-- @Liquipedia
-- page=Module:MapTable/Lib/Parse
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Opponent = Lua.import('Module:Opponent')
local Table = Lua.import('Module:Table')

local MapTableTypes = Lua.import('Module:MapTable/Types')

local MapTableParse = {}

---Reads the map rows from the indexed template arguments
---@param args table
---@return TrackmaniaMapTableRows
function MapTableParse.readRows(args)
	return Array.map(
		Array.mapIndexes(function(index) return args[index] end),
		Json.parseIfString
	)
end

---Reads the mapper entries of a single row
---@param row TrackmaniaMapTableRowArgs
---@return TrackmaniaMapTableMapper[]
function MapTableParse.readMappers(row)
	---@type TrackmaniaMapTableMapper[]
	local mappers = {}

	for key, mapper, index in Table.iter.pairsByPrefix(row, MapTableTypes.MAPPER_PREFIXES, {requireIndex = false}) do
		---@type TrackmaniaMapTableMapper
		local player = Table.merge(
			Opponent.readSinglePlayerArgs{
				name = mapper,
				link = row[key .. 'link'],
				flag = row[key .. 'flag'],
			},
			{index = index}
		)

		table.insert(mappers, player)
	end

	return mappers
end

---Builds the full links of a single map
---@param mapInput table
---@return {[string]: string}
function MapTableParse.makeFullLinks(mapInput)
	return Table.filterByKey(
		Links.makeFullLinksForTableItems(Links.transform(mapInput), MapTableTypes.LINK_VARIANT),
		function(_, link) return link ~= '' end
	)
end

return MapTableParse
