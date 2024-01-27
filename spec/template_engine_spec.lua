--- Triple Comment to Enable our LLS Plugin
describe('templating engine', function()
	local TemplateEngine = require('Module:TemplateEngine')

	local TEST_DATA = {
		a = {a = 'baz', b = 'foo'},
		b = 2,
		foo = {'bar', 'baz'},
		d = {},
		math = function(self) return self.b + 5 end,
		bold = function(text, render) return '<b>' .. render(text) .. '</b>' end,
		locations = {
			{country = 'Sweden', city = 'Stockholm'},
			{country = 'The Netherlands', city = 'Utrecht'},
			{country = 'USA', city = 'Santa Monica'},
		},
		html = '<b>a</b>'
	}

	it('variables', function()
		assert.are_equal('2foo', TemplateEngine:render('{{b}}{{a.b}}', TEST_DATA))
	end)

	it('variable function', function()
		assert.are_equal('7', TemplateEngine:render('{{math}}', TEST_DATA))
	end)

	it('escaped variable', function()
		assert.are_equal('<b>a</b>&#60;b&#62;a&#60;/b&#62;', TemplateEngine:render('{{&html}}{{html}}', TEST_DATA))
	end)

	it('comment', function()
		assert.are_equal('', TemplateEngine:render('{{!A Comment}}', TEST_DATA))
	end)

	it('section array', function()
		assert.are_equal('*bar*baz', TemplateEngine:render('{{#foo}}*{{.}}{{/foo}}', TEST_DATA))
	end)

	it('section table', function()
		assert.are_equal(
			'Stockholm, Sweden\nUtrecht, The Netherlands\nSanta Monica, USA\n',
			TemplateEngine:render('{{#locations}}{{city}}, {{country}}\n{{/locations}}', TEST_DATA)
		)
	end)

	it('section if', function()
		assert.are_equal('HAI', TemplateEngine:render('{{#b}}HAI{{/b}}{{#c}}BAI{{/c}}', TEST_DATA))
	end)

	it('section function', function()
		assert.are_equal('<b>foo</b>', TemplateEngine:render('{{#bold}}{{a.b}}{{/bold}}', TEST_DATA))
	end)

	it('nested section', function()
		assert.are_equal('HAI', TemplateEngine:render('{{#a.b}}HAI{{/a.b}}', TEST_DATA))
	end)

	it('inverted section', function()
		assert.are_equal('BAIKAI',
			TemplateEngine:render('{{^foo}}HAI1{{/foo}}{{^b}}HAI2{{/b}}{{^a}}HAI2{{/a}}{{^c}}BAI{{/c}}{{^d}}KAI{{/d}}',
				TEST_DATA)
		)
	end)
end)
