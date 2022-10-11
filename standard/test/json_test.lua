---
-- @Liquipedia
-- wiki=commons
-- page=Module:Json/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Json = Lua.import('Module:Json', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testStringify()
	self:assertEquals('[]', Json.stringify{})
	self:assertEquals('{"abc":"def"}', Json.stringify{abc = 'def'})
	self:assertEquals('{"abc":["b","c"]}', Json.stringify{abc = {'b', 'c'}})
end

function suite:testParse()
	self:assertDeepEquals({}, (Json.parse('[]')))
	self:assertDeepEquals({abc = 'def'}, (Json.parse('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parse('{"abc":["b","c"]}')))
	self:assertDeepEquals({}, (Json.parse{a = 1}))
	self:assertDeepEquals({}, (Json.parse('banana')))
end

function suite:testParseIfString()
	self:assertDeepEquals({}, (Json.parseIfString('[]')))
	self:assertDeepEquals({abc = 'def'}, (Json.parseIfString('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfString('{"abc":["b","c"]}')))
	self:assertDeepEquals({a = 1}, (Json.parseIfString{a = 1}))
	self:assertDeepEquals({}, (Json.parseIfString('banana')))
end

function suite:testParseIfTable()
	self:assertDeepEquals({}, (Json.parseIfTable('[]')))
	self:assertDeepEquals({abc = 'def'}, (Json.parseIfTable('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfTable('{"abc":["b","c"]}')))
	self:assertDeepEquals(nil, (Json.parseIfTable{a = 1}))
	self:assertDeepEquals(nil, (Json.parseIfTable('banana')))
end

return suite
