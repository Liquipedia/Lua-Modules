---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Patch = Lua.import('Module:Infobox/Patch')

---@class RuneterraPatchInfobox: PatchInfobox
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
	---@param prefix string
	---@return string?
	local buildLink = function(prefix)
		if not args[prefix] then return end
		local link = args[prefix .. ' link'] or (args[prefix] .. ' Patch')
		return link .. '|' .. args[prefix]
	end
	return {previous = buildLink('previous'), next = buildLink('next')}
end

return CustomPatch
