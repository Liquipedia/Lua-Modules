---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local TemplateEngine = Lua.import('Module:TemplateEngine', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

local TEST_DATA = {a = {b = 'foo'}, b = 2, foo = {'bar', 'baz'}}

function suite:testVariables()
	self:assertEquals('2foo', TemplateEngine:render('{{b}}{{a.b}}', TEST_DATA))
end

function suite:testLoops()
	self:assertEquals(' bar baz', TemplateEngine:render('{{#foo}} {{.}}{{/foo}}', TEST_DATA))
end

function suite:testIf()
	self:assertEquals('HAI', TemplateEngine:render('{{#b}}HAI{{/b}}{{#c}}BAI{{/c}}', TEST_DATA))
end

function suite:testNotIf()
	self:assertEquals('BAI', TemplateEngine:render('{{^foo}}HAI1{{/foo}}{{^b}}HAI2{{/b}}{{^c}}BAI{{/c}}', TEST_DATA))
end

function suite:testNestedSections()
	self:assertEquals('HAI', TemplateEngine:render('{{#a.b}}HAI{{/a.b}}', TEST_DATA))
end

return suite
