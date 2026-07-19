---
-- @Liquipedia
-- page=Module:Infobox/Extension/PatchAuto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Patch = Lua.import('Module:Patch')
local String = Lua.import('Module:StringUtils')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

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

	local endDate = data.endDate or DateExt.toYmdInUtc(DateExt.getCurrentTimestamp())

	patch = patch or PatchAuto._getPatch(data.startDate)
	endPatch = endPatch or PatchAuto._getPatch(endDate)

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

	local patchData = Patch.queryPatches{
		additionalConditions = ConditionNode(ColumnName('pagename'), Comparator.eq, patch:gsub(' ', '_')),
		limit = 1
	}[1]

	assert(patchData, '"' .. patch .. '" is not a valid patch')

	patchDisplay = String.nilIfEmpty(patchData.displayName) or patch
	return {link = patch, display = patchDisplay}
end

---@param date string
---@return {link: string?, display: string?}
function PatchAuto._getPatch(date)
	local patch = Patch.getPatchByDate(date) or {}

	return {link = patch.pageName, display = patch.displayName}
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
