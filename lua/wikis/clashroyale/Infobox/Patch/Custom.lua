---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch')

local CustomPatch = Class.new()

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = Patch(frame)
	patch.args.informationType = 'Version'

	patch.getChronologyData = CustomPatch.getChronologyData

	return patch:createInfobox()
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = 'Version ' .. args.previous .. '|' .. args.previous
	end
	if args.next then
		data.next = 'Version ' .. args.next .. '|' .. args.next
	end
	return data
end

return CustomPatch
