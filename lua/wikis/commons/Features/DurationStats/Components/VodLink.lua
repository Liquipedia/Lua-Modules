---
-- @Liquipedia
-- page=Module:Features/DurationStats/Components/VodLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local VodButton = Lua.import('Module:Widget/Match/VodButton')

local DurationStatsVodLink = {}

---Returns the VOD to show for a game: the game's own VOD if there is one, otherwise the match VOD.
---Returns nothing if neither has a VOD.
---@param entry DurationStatsEntry
---@return string?
---@return boolean?
function DurationStatsVodLink.getVod(entry)
	local gameVod = Logic.nilIfEmpty(entry.game.vod)
	if gameVod then
		return gameVod, true
	end

	local matchVod = Logic.nilIfEmpty((entry.match or {}).vod)
	if matchVod then
		return matchVod, false
	end
end

---Displays the VOD link of a game, or nothing if it has no VOD.
---@param entry DurationStatsEntry
---@return Renderable?
function DurationStatsVodLink.display(entry)
	local vod, isGameVod = DurationStatsVodLink.getVod(entry)
	if not vod then return end

	-- a match VOD covers the whole match, so only a game's own VOD is labelled with its game number
	return VodButton{vodLink = vod, gameNumber = isGameVod and entry.gameId or nil, variant = 'dropdown'}
end

return DurationStatsVodLink
