---
-- @Liquipedia
-- page=Module:Features/MapTable/Api/Mappers
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local MapTableMappers = {}

---Resolves the page name of a mapper and their flag
---@param mapper TrackmaniaMapTableMapper
---@return TrackmaniaMapTableMapper
local function resolveMapper(mapper)
	PlayerExt.populatePageName(mapper)
	mapper.flag = mapper.flag or PlayerExt.fetchPlayerFlag(mapper.pageName)

	return mapper
end

---Resolves every mapper, keeping the order they were read
---@param mappers TrackmaniaMapTableMappers
---@return TrackmaniaMapTableMappers
function MapTableMappers.resolveMappers(mappers)
	return Array.map(mappers, function(rowMappers)
		return Array.map(rowMappers, resolveMapper)
	end)
end

return MapTableMappers
