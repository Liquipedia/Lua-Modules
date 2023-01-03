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

local TEST_DATA = {a = {a = 'baz', b = 'foo'}, b = 2, foo = {'bar', 'baz'}, d = {},
	math = function (self) return self.b + 5 end,
	bold = function (text, render) return '<b>' .. render(text) .. '</b>' end,
	locations = {
		{country = 'Sweden', city = 'Stockholm'},
		{country = 'The Netherlands', city = 'Utrecht'},
		{country = 'USA', city = 'Santa Monica'},
	},
	html = '<b>a</b>'
}

function suite:testVariables()
	self:assertEquals('2foo', TemplateEngine:render('{{b}}{{a.b}}', TEST_DATA))
end

function suite:testVariableFunction()
	self:assertEquals('7', TemplateEngine:render('{{math}}', TEST_DATA))
end

function suite:testVariableEscape()
	self:assertEquals('<b>a</b>&#60;b&#62;a&#60;/b&#62;', TemplateEngine:render('{{&html}}{{html}}', TEST_DATA))
end

function suite:testComments()
	self:assertEquals('', TemplateEngine:render('{{!A Comment}}', TEST_DATA))
end

function suite:testSectionArrays()
	self:assertEquals('*bar*baz', TemplateEngine:render('{{#foo}}*{{.}}{{/foo}}', TEST_DATA))
end

function suite:testSectionTables()
	self:assertEquals(
		'Stockholm, Sweden\nUtrecht, The Netherlands\nSanta Monica, USA\n',
		TemplateEngine:render('{{#locations}}{{city}}, {{country}}\n{{/locations}}', TEST_DATA)
	)
end

function suite:testSectionIf()
	self:assertEquals('HAI', TemplateEngine:render('{{#b}}HAI{{/b}}{{#c}}BAI{{/c}}', TEST_DATA))
end

function suite:testSectionFunction()
	self:assertEquals('<b>foo</b>', TemplateEngine:render('{{#bold}}{{a.b}}{{/bold}}', TEST_DATA))
end

function suite:testNestedSections()
	self:assertEquals('HAI', TemplateEngine:render('{{#a.b}}HAI{{/a.b}}', TEST_DATA))
end

function suite:testInvertedSection()
	self:assertEquals('BAIKAI',
		TemplateEngine:render('{{^foo}}HAI1{{/foo}}{{^b}}HAI2{{/b}}{{^a}}HAI2{{/a}}{{^c}}BAI{{/c}}{{^d}}KAI{{/d}}',
		TEST_DATA)
	)
end

return suite
