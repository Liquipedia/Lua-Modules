---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local RatingsStorageFactory = require('Module:Ratings/Storage/Factory')

local RatingsDisplay = {}

---@class RatingsEntry
---@field matches integer
---@field opponent standardOpponent
---@field rating number
---@field region string
---@field streak integer
---@field progression table[]

---@class RatingsDisplayInterface
---@field build fun(teamRankings: RatingsEntry[]):string

---@alias RatingsDisplayGetRankings fun(progressionLimit?: integer):RatingsEntry[]

local LIMIT_HISTORIC_ENTRIES = 24 -- How many historic entries are fetched

--- Entry point for the ratings display in table list display mode
---@param frame Frame
---@return string
function RatingsDisplay.list(frame)
	local Display = require('Module:Ratings/Display/List')
	return RatingsDisplay.make(frame, Display)
end

---@param frame Frame
---@param displayClass RatingsDisplayInterface
---@return string
function RatingsDisplay.make(frame, displayClass)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsStorageFactory.createGetRankings(args)(LIMIT_HISTORIC_ENTRIES)

	return displayClass.build(teamRankings)
end

return RatingsDisplay
