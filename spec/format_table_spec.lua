--- Triple Comment to Enable our LLS Plugin
describe('table formatter', function()
	local TableFormatter = require('Module:Format/Table')

	it('test', function()
		assert.are_equal(
			'<pre class="selectall">{}</pre>',
			tostring(TableFormatter.toLuaCode{})
		)
		assert.are_same(
			[[<pre class="selectall">{
	5,
	10,
	[10] = 100,
	['a'] = 'a',
	['a\'b'] = ']] .. mw.text.nowiki('te\\\'st') .. [[',
	['b'] = {
		['b'] = 'b',
	},
	['c'] = 1,
	['trueBool'] = true,
	['zFunction'] = ]] .. tostring(tostring) .. [[,
}</pre>]],
			tostring(
				TableFormatter.toLuaCode{
					a = 'a',
					b = {b = 'b'},
					c = 1,
					5,
					10,
					[10] = 100,
					['a\'b'] = 'te\'st',
					trueBool = true,
					zFunction = tostring
				}
			)
		)
		assert.are_equal(
			[[<pre class="selectall">{
	[10] = 100,
	['a'] = 'a',
	['b'] = {
		['b'] = 'b',
	},
	['c'] = 1,
	['x'] = ']] .. mw.text.nowiki('[[Module:Format/Table/testcases|aa]]') .. [[',
	['z'] = ']] .. mw.text.nowiki('https://discord.com/invite/WaQRYSa') .. [[',
}</pre>]],
			tostring(TableFormatter.toLuaCode{
				a = 'a', b = {b = 'b'}, c = 1, [10] = 100,
				x = '[[Module:Format/Table/testcases|aa]]',
				z = 'https://discord.com/invite/WaQRYSa'
			})
		)
	end)
end)
