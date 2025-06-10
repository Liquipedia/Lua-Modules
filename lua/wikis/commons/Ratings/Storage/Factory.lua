---
-- @Liquipedia
-- page=Module:Ratings/Storage/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')

---@class RatingsEntry
---@field opponent standardOpponent
---@field rating number
---@field region string
---@field streak integer
---@field change integer? # nil = new, otherwise indicate change in rank
---@field progression {date: string, rating: number?, rank: integer?}[]

---@alias RatingsDisplayGetRankings fun(teamLimit: integer, progressionLimit?: integer):RatingsEntry[]

local RatingsStorageFactory = {}

---@param props {storageType: 'extension', id: string?, date: string?}
---@return RatingsDisplayGetRankings
function RatingsStorageFactory.createGetRankings(props)
	local storageType = props.storageType
	if storageType == 'extension' then
		local RatingsStorageExtension = require('Module:Ratings/Storage/Extension')
		local date = props.date
		return FnUtil.curry(RatingsStorageExtension.getRankings, date)
	end

	error('Unknown storage type: ' .. (storageType or ''))
end

return RatingsStorageFactory
