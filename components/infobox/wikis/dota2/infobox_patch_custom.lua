---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local CustomPatch = Class.new()

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = Patch(frame)

	patch.getChronologyData = CustomPatch.getChronologyData

	return patch:createInfobox()
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local informationType = self:getInformationType(args):lower()

	local data = {}
	if args.previous then
		data.previous = informationType ..' ' .. args.previous .. '|' .. args.previous
	end
	if args.next then
		data.next = informationType ..' ' .. args.next .. '|' .. args.next
	end
	return data
end

return CustomPatch
