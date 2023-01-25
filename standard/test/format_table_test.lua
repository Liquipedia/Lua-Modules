---
-- @Liquipedia
-- wiki=commons
-- page=Module:Format/Table/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local TableFormatter = Lua.import('Module:Format/Table', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testClass()
	self:assertEquals(
		'<pre class="selectall">{}</pre>',
		tostring(TableFormatter.toLuaCode{})
	)
	self:assertEquals(
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
	['zFunction'] = function,
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
	self:assertEquals(
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
end

return suite
