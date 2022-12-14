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
	self:assertEquals('2foo bar baz', TemplateEngine.render('{{b}}{{a.b}}{{#bar}} {{.}}{{/bar}}', {a = {b = 'foo'}, b = 2, bar = {'bar', 'baz'}}))
end

return suite
