---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Extension/PatchAuto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')

local TODAY = os.date('!%Y-%m-%d', os.time())

local PatchAuto = {}

---@param data table
---@param args table
---@return table
function PatchAuto.run(data, args)
	local patch = PatchAuto._fetchPatchData(data.patch, args.patch_display)
	local endPatch = PatchAuto._fetchPatchData(data.endPatch, args.epatch_display)
	if patch and endPatch or not data.startDate then
		return PatchAuto._toData(data, patch or {}, endPatch or {})
	end

	local endDate = data.endDate or TODAY --[[@as string]]
	local patches = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::patch]] AND ([[date::<' .. endDate .. ']] OR [[date::' .. endDate .. ']])',
		query = 'name, pagename, date',
		limit = 5000,
		order = 'date desc',
	})
	patch = patch or PatchAuto._getPatch(patches, data.startDate)
	endPatch = endPatch or PatchAuto._getPatch(patches, endDate)

	return PatchAuto._toData(data, patch or {}, endPatch or {})
end

---@param patch string?
---@param patchDisplay string?
---@return {link: string?, display: string?}?
function PatchAuto._fetchPatchData(patch, patchDisplay)
	if not patch then
		return
	elseif patchDisplay then
		patch = patch:gsub(' ', '_')
		return {link = patch, display = patchDisplay}
	end

	patch = patch:gsub(' ', '_')

	local patchData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::patch]] AND [[pagename::' .. patch .. ']]',
		query = 'name',
		limit = 1
	})[1]

	assert(patchData, '"' .. patch .. '" is not a valid patch')

	patchDisplay = String.nilIfEmpty(patchData.name) or patch:gsub('_', ' ')
	return {link = patch, display = patchDisplay}
end

---@param patches {pagename: string, name: string?, date: string}[]
---@param date string
---@return table
function PatchAuto._getPatch(patches, date)
	for _, patch in ipairs(patches) do
		if patch.date <= date then
			return {link = patch.pagename, display = patch.name}
		end
	end

	return {}
end

---@param data table
---@param patch {link: string?, display: string?}
---@param endPatch {link: string?, display: string?}
---@return table
function PatchAuto._toData(data, patch, endPatch)
	data.patch = patch.link
	data.endPatch = endPatch.link or data.patch
	data.patchDisplay = patch.display
	-- only set endPatch display if not equal to patch display
	if patch.display ~= endPatch.display then
		data.endPatchDisplay = endPatch.display
	end

	return data
end

return PatchAuto
