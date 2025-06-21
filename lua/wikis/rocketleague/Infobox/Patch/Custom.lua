---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Patch = Lua.import('Module:Infobox/Patch')

---@class RockatleaguePatchInfobox: PatchInfobox
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
	local makeLink = function(input)
		return input and ('Version ' .. input .. '|V' .. input) or nil
	end
	return {previous = makeLink(args.previous), next = makeLink(args.next)}
end

---@param args table
---@return string[]
function CustomPatch:getWikiCategories(args)
	return {'Versions'}
end

---@param args table
---@return string
function Patch:getInformationType(args)
	return 'Version'
end

return CustomPatch
