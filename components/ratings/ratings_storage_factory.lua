---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Storage/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')

---@class RatingsEntry
---@field opponent standardOpponent
---@field rating number
---@field region string
---@field streak integer
---@field progression {date: string, rating: number?, ranking: integer?}[]

---@alias RatingsDisplayGetRankings fun(teamLimit: integer, progressionLimit?: integer):RatingsEntry[]

local RatingsStorageFactory = {}

---@param props {storageType: 'lpdb'|'extension', id: string?, date: string?}
---@return RatingsDisplayGetRankings
function RatingsStorageFactory.createGetRankings(props)
	local storageType = props.storageType

	if storageType == 'lpdb' then
		local RatingsStorageLpdb = require('Module:Ratings/Storage/Lpdb')
		assert(props.id, 'ID is required for LPDB storage')
		return FnUtil.curry(RatingsStorageLpdb.getRankings, props.id)
	elseif storageType == 'extension' then
		local RatingsStorageExtension = require('Module:Ratings/Storage/Extension')
		local date = props.date
		return FnUtil.curry(RatingsStorageExtension.getRankings, date)
	end

	error('Unknown storage type: ' .. (storageType or ''))
end


return RatingsStorageFactory
