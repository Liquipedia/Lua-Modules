---
-- @Liquipedia
-- page=Module:Features/MapTable/Api/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')

local MapTableStore = {}

---Builds the extradata of a single map
---@param mappers TrackmaniaMapTableMapper[]
---@param links {[string]: string}?
---@return table
local function buildExtradata(mappers, links)
	local extradata = {}
	for _, mapper in ipairs(mappers) do
		extradata['author' .. mapper.index] =
			mapper.pageName and mapper.pageName:gsub(' ', '_') or ''
		extradata['author' .. mapper.index .. 'dn'] = mapper.displayName
		extradata['author' .. mapper.index .. 'flag'] = mapper.flag or ''
	end

	if Table.isNotEmpty(links) then
		extradata.links = links
	end

	return extradata
end

---Creates an LPDB map record per map, as `map` datapoints
---@param rows TrackmaniaMapTableRows
---@param mappers TrackmaniaMapTableMappers
---@param links TrackmaniaMapTableLinks
function MapTableStore.storeMaps(rows, mappers, links)
	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		return
	end

	Array.forEach(rows, function(row, rowIndex)
		local mapName = row.map
		if Logic.isEmpty(mapName) then
			return
		end

		mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. mapName, Json.stringifySubTables({
			name = mapName,
			type = 'map',
			extradata = buildExtradata(mappers[rowIndex], links[rowIndex]),
		}))
	end)
end

return MapTableStore
