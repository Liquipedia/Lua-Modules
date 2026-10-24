---
-- @Liquipedia
-- page=Module:Features/DurationStats/Types
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Types = {}

---One game together with the match it belongs to (nil if the match could not be found),
---and the values the table displays for it.
---@class DurationStatsEntry
---@field game MatchGroupUtilGame
---@field pageName string
---@field gameId string
---@field match MatchGroupUtilMatch?
---@field stageName string
---@field winner standardOpponent?
---@field loser standardOpponent?

return Types
