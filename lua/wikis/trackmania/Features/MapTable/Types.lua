---
-- @Liquipedia
-- page=Module:Features/MapTable/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---A single map row, as read from the indexed template arguments
---@class TrackmaniaMapTableRowArgs: table<string, string?>
---@field map string?
---@field mapper string?
---@field mapperFlag string?

---A single mapper of a map, as it appears in the mapper cell
---@class TrackmaniaMapTableMapper: standardPlayer
---@field index integer

---The map rows, in the order they were given
---@alias TrackmaniaMapTableRows TrackmaniaMapTableRowArgs[]

---A parsed map: name of the map, mappers and links
---@class TrackmaniaMapTableMap
---@field name string
---@field mappers TrackmaniaMapTableMapper[]
---@field links {[string]: string}

---The maps, in the order they were given
---@alias TrackmaniaMapTableMaps TrackmaniaMapTableMap[]

local MapTableTypes = {}

---Variant used when building the links of a map, decides which icon set is used
MapTableTypes.LINK_VARIANT = 'map'

---Argument prefixes for a mapper
MapTableTypes.MAPPER_PREFIXES = {'mapper', 'author', 'a'}

return MapTableTypes
