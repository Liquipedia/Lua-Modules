---
-- @Liquipedia
-- page=Module:Infobox/Extension/CountryCategory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local CountryCategory = {}

---@param args table<string, string>
---@param categoryPostfix string
---@return string[]
function CountryCategory.run(args, categoryPostfix)
	local categories = {}
	for _, country in Table.iter.pairsByPrefix(args, 'country', {requireIndex = false}) do
		local nationality = Flags.getLocalisation(country)
		if Logic.isEmpty(nationality) then
			table.insert(categories, 'Unrecognised Country')
		else
			table.insert(categories, nationality .. ' ' .. categoryPostfix)
		end
	end

	return categories
end

return CountryCategory
