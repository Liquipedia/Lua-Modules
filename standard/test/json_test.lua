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
	self:assertEquals('{"abc":{"1":"b","2":"c"}}', Json.stringify{abc = {'b', 'c'}})
	self:assertTrue(string.len(Json.stringify(mw.loadData('Module:Flags/MasterData'))) > 3)
	self:assertEquals(nil, Json.stringify())
	self:assertEquals('string', Json.stringify('string'))
	self:assertEquals('[1,2,3]', Json.stringify({1, 2, 3}, {asArray = true}))
	self:assertEquals('{"1":1,"2":2,"3":3}', Json.stringify{1, 2, 3})
end

function suite:testParse()
	self:assertDeepEquals({}, (Json.parse('[]')))
	self:assertDeepEquals({}, (Json.parse('{}')))
	self:assertDeepEquals({abc = 'def'}, (Json.parse('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parse('{"abc":["b","c"]}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parse('{"abc":{"1":"b","2":"c"}}')))
	self:assertDeepEquals({}, (Json.parse{a = 1}))
	self:assertDeepEquals({}, (Json.parse('banana')))
end

function suite:testParseIfString()
	self:assertDeepEquals({}, (Json.parseIfString('[]')))
	self:assertDeepEquals({}, (Json.parseIfString('{}')))
	self:assertDeepEquals({abc = 'def'}, (Json.parseIfString('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfString('{"abc":["b","c"]}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfString('{"abc":{"1":"b","2":"c"}}')))
	self:assertDeepEquals({a = 1}, (Json.parseIfString{a = 1}))
	self:assertDeepEquals({}, (Json.parseIfString('banana')))
end

function suite:testParseIfTable()
	self:assertDeepEquals({}, (Json.parseIfTable('[]')))
	self:assertDeepEquals({}, (Json.parseIfTable('{}')))
	self:assertDeepEquals({abc = 'def'}, (Json.parseIfTable('{"abc":"def"}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfTable('{"abc":["b","c"]}')))
	self:assertDeepEquals({abc = {'b', 'c'}}, (Json.parseIfTable('{"abc":{"1":"b","2":"c"}}')))
	self:assertDeepEquals(nil, (Json.parseIfTable{a = 1}))
	self:assertDeepEquals(nil, (Json.parseIfTable('banana')))
end

function suite:testStringifySubTables()
	self:assertDeepEquals({}, Json.stringifySubTables{})
	self:assertDeepEquals({abc = 'def'}, Json.stringifySubTables{abc = 'def'})
	self:assertDeepEquals({abc = '{"1":"b","2":"c"}'}, Json.stringifySubTables{abc = {'b', 'c'}})
	self:assertDeepEquals({a = '{"d":1,"b":"c"}', e = 'f'}, Json.stringifySubTables{a = {b = 'c', d = 1}, e = 'f'})
end

return suite
