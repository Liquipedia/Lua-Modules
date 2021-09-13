---
-- @Liquipedia
-- wiki=commons
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicHDB = require('Module:HiddenDataBox')
local CustomHDB = {}

function CustomHDB.run(args)
	BasicHDB.addCustomVariables = CustomHDB.addCustomVariables
	return BasicHDB.run(args)
end

function CustomHDB:addCustomVariables(args, queryResult)
	--add your wiki specific vars here
end

return Class.export(CustomHDB)
