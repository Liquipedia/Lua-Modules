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

function suite:testEngine()
	self:assertEquals('foo bar baz', TemplateEngine.eval('${a.b}*{foreach foo in bar} ${foo}*{end}', {a = {b = 'foo'}, bar = {'bar', 'baz'}}))
end

return suite
