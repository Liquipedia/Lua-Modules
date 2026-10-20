---
-- @Liquipedia
-- page=Module:Features/DurationStats/Components/VodLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local VodLink = Lua.import('Module:VodLink')

local DurationStatsVodLink = {}

---Returns the VOD to show for a game: the match VOD if there is one, otherwise the game's own VOD.
---Returns nothing if neither has a VOD.
---@param entry DurationStatsEntry
---@return string?
---@return boolean?
function DurationStatsVodLink.getVod(entry)
	local matchVod = Logic.nilIfEmpty((entry.match or {}).vod)
	if matchVod then
		return matchVod, false
	end

	local gameVod = Logic.nilIfEmpty(entry.game.vod)
	if gameVod then
		return gameVod, true
	end
end

---Displays the VOD link of a game, or nothing if it has no VOD.
---@param entry DurationStatsEntry
---@return Html?
function DurationStatsVodLink.display(entry)
	local vod, isGameVod = DurationStatsVodLink.getVod(entry)
	if not vod then return end

	-- a match VOD covers the whole match, so only a game's own VOD is labelled with its game number
	return VodLink.display{vod = vod, gamenum = isGameVod and entry.game.match2gameid or nil}
end

return DurationStatsVodLink
