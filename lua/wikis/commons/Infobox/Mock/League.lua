---
-- @Liquipedia
-- page=Module:Infobox/Mock/League
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local League = Lua.import('Module:Infobox/League')
local Variables = Lua.import('Module:Variables')

local mockTournament = {}

function mockTournament.setUp(data)
	League:_definePageVariables(data)
end

function mockTournament.tearDown()
	League:_definePageVariables({})
	Variables.varDefine('tournament_parent')
end

return mockTournament
