---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Patch = Lua.import('Module:Infobox/Patch')

---@class WildriftPatchInfobox: PatchInfobox
local CustomPatch = Class.new(Patch)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local customPatch = CustomPatch(frame)
	return customPatch:createInfobox()
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	---@param input string?
	---@return string?
	local prefixIfExists = function(input)
		return input and ('Patch ' .. input) or nil
	end
	return {previous = prefixIfExists(args.previous), next = prefixIfExists(args.next)}
end

return CustomPatch
