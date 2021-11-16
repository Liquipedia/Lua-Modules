local Class = require('Module:Class')
local Json = require('Module:Json')

local SquadPerson = {}

function SquadPerson.parse(args)
	return Json.stringify(args)
end

return Class.export(SquadPerson)
