---
-- @Liquipedia
-- wiki=commons
-- page=Module:Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Page = require('Module:Page')

local Player = {}

---@class StandardPlayer
---@field displayName string
---@field pageName string

---@param link string
---@return StandardPlayer?
function Player.getPlayerByPagename(link)
	local page = Page.pageifyLink(link)
	local record = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. page .. ']]',
		order = 'date desc',
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Player.playerFromRecord(record)
end

---@param record player
---@return StandardPlayer
function Player.playerFromRecord(record)
	local player = {
		displayName = record.name,
		pageName = record.pagename,
	}

	return player
end

return Player
