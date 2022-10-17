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
		'<pre class="selectall">{'
			.. '\n\t5,'
			.. '\n\t10,'
			.. '\n\t[10] = 100,'
			.. '\n\t[\'a\'] = \'a\','
			.. '\n\t[\'a\\\'b\'] = \'te\\\'st\','
			.. '\n\t[\'b\'] = {'
			.. '\n\t\t[\'b\'] = \'b\','
			.. '\n\t},'
			.. '\n\t[\'c\'] = 1,'
			.. '\n}</pre>',
		tostring(TableFormatter.toLuaCode{a = 'a', b = {b = 'b'}, c = 1, 5, 10, [10] = 100, ['a\'b'] = 'te\'st'})
	)
	self:assertEquals(
		'<pre class="selectall">{'
			.. '\n\t[10] = 100,'
			.. '\n\t[\'a\'] = \'a\','
			.. '\n\t[\'a\\\'b\'] = \'te\\\'st\','
			.. '\n\t[\'b\'] = {'
			.. '\n\t\t[\'b\'] = \'b\','
			.. '\n\t},'
			.. '\n\t[\'c\'] = 1,'
			.. '\n\t[\'x\'] = \'[[Module:Format/Table/testcases]]\','
			.. '\n\t[\'z\'] = \'https://discord.com/invite/WaQRYSa\','
			.. '\n}</pre>',
		tostring(TableFormatter.toLuaCode{
			a = 'a', b = {b = 'b'}, c = 1, [10] = 100, ['a\'b'] = 'te\'st',
			x = '[[Module:Format/Table/testcases]]',
			z = 'https://discord.com/invite/WaQRYSa'
		})
	)
end

return suite
