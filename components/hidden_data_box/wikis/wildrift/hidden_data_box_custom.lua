---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicHiddenDataBox = require('Module:HiddenDataBox')
local Variables = require('Module:Variables')

local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox:addCustomVariables(args, queryResult)
	BasicHiddenDataBox:checkAndAssign(
		'tournament_publishertier',
		args.riotpremier,
		queryResult.publishertier
	)
	Variables.varDefine('tournament_riot_premier', Variables.varDefault('tournament_publishertier', ''))
end

return Class.export(CustomHiddenDataBox)
