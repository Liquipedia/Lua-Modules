--
-- @Liquipedia
-- wiki=commons
-- page=Module:Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = require('Module:Info')

local Patch = {}

---@class StandardPatch
---@field displayName string
---@field pageName string
---@field releaseDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?

local function datapointType()
	if Info.wikiName == 'dota2' then
		return 'version'
	end
	return 'patch'
end

---@param date string
---@return StandardPatch?
function Patch.getPatchByDate(date)
	local record = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::' .. datapointType() .. ']] AND ([[date::<' .. date .. ']] OR [[date::' .. date .. ']])',
		order = 'date desc',
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Patch.patchFromRecord(record)
end

---@param record datapoint
---@return StandardPatch
function Patch.patchFromRecord(record)
	local patch = {
		displayName = record.name,
		pageName = record.pagename,
		releaseDate = record.date,
	}

	return patch
end

return Patch
