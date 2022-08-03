---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicHiddenDataBox = require('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	--add your wiki specific vars here
end

return Class.export(CustomHiddenDataBox)
