---
-- @Liquipedia
-- page=Module:Features/Crosshair/Api/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CrosshairStore = {}

---@param crosshair Crosshair
---@param reference string?
---@param date string?
function CrosshairStore.storeCrosshair(crosshair, reference, date)
    local objectname = mw.title.getCurrentTitle().text .. '_crosshair'
	mw.ext.LiquipediaDB.lpdb_settings(objectname, {
		name = mw.title.getCurrentTitle().text,
		reference = (reference == 'player' and 'player' or reference or ''),
		lastupdated = (date ~= nil and date or ''),
		gamesettings = crosshair,
		type = 'crosshair'
	})
end

return CrosshairStore
