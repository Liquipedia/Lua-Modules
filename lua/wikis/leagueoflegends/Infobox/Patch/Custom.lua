---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch')

---@class LoLPatchInfobox: PatchInfobox
local CustomPatch = Class.new(Patch)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)

	return patch:createInfobox()
end

---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function CustomPatch:addToLpdb(lpdbData, args)
	lpdbData.information = Logic.emptyOr(args.patch, lpdbData.information)
	return lpdbData
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = 'Patch ' .. args.previous .. '|' .. args.previous
	end
	if args.next then
		data.next = 'Patch ' .. args.next .. '|' .. args.next
	end
	return data
end

return CustomPatch
