---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Storage/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')

local RatingsStorageFactory = {}

---@param args {storageType: 'lpdb'|'extension', id: string?}
---@return RatingsDisplayGetRankings
function RatingsStorageFactory.createGetRankings(args)
	local storageType = args.storageType

	if storageType == 'lpdb' then
		local RatingsStorageLpdb = require('Module:Ratings/Storage/Lpdb')
		assert(args.id, 'ID is required for LPDB storage')
		return FnUtil.curry(RatingsStorageLpdb.getRankings, args.id)
	elseif storageType == 'extension' then
		local RatingsStorageExtension = require('Module:Ratings/Storage/Extension')
		return RatingsStorageExtension.getRankings
	end

	error('Unknown storage type: ' .. (storageType or ''))
end


return RatingsStorageFactory
