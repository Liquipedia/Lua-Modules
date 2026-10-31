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
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local MapTableStore = {}

---Builds the extradata of a single map
---@param mappers TrackmaniaMapTableMapper[]
---@param links {[string]: string}?
---@return table
local function buildExtradata(mappers, links)
	local extradata = {}
	Array.forEach(mappers, function(mapper)
		extradata['author' .. mapper.index .. 'dn'] = mapper.displayName

		local pageName = mapper.pageName and mapper.pageName:gsub(' ', '_')
		if String.isNotEmpty(pageName) then
			extradata['author' .. mapper.index] = pageName
		end
		if String.isNotEmpty(mapper.flag) then
			extradata['author' .. mapper.index .. 'flag'] = mapper.flag
		end
	end)

	if Table.isNotEmpty(links) then
		extradata.links = links
	end

	return extradata
end

---Creates an LPDB map record per map, as `map` datapoints
---@param maps TrackmaniaMapTableMaps
function MapTableStore.storeMaps(maps)
	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		return
	end

	Array.forEach(maps, function(map)
		local mapName = map.name
		if Logic.isEmpty(mapName) then
			return
		end

		mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. mapName, Json.stringifySubTables({
			name = mapName,
			type = 'map',
			extradata = buildExtradata(map.mappers, map.links),
		}))
	end)
end

return MapTableStore
