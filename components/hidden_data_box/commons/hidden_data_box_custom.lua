local Class = require('Module:Class')
local Variables = require('Module:Variables')
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
