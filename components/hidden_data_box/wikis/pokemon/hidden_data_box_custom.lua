---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')

local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

return Class.export(CustomHiddenDataBox)
