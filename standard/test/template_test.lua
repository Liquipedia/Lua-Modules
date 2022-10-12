---
-- @Liquipedia
-- wiki=commons
-- page=Module:Template/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Template = Lua.import('Module:Template', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testSafeExpand()
	local frame = mw.getCurrentFrame()
	self:assertEquals('[[Template:PageThatsDead]]', Template.safeExpand(frame, 'PageThatsDead'))
	self:assertEquals('??', Template.safeExpand(frame, '??', {}))
end

function suite:testExpandTemplate()
	local frame = mw.getCurrentFrame()
	self:assertThrows(Template.safeExpand(frame, 'PageThatsDead'))
	self:assertEquals('??', Template.safeExpand(frame, '??', {}))
end

function suite:testStashArgsRetrieve()
	Template.stashArgs{foo = 3, bar = 5, namespace = 'Foo'}
	self:assertDeepEquals({}, Template.retrieveReturnValues('Bar'))
	self:assertDeepEquals({{foo = 3, bar = 5}}, Template.retrieveReturnValues('Foo'))
	self:assertDeepEquals({}, Template.retrieveReturnValues('Foo'))
	Template.stashArgs{foo = 3, bar = 5, namespace = 'Foo'}
	Template.stashArgs{foo = 1, bar = 9, namespace = 'Foo'}
	self:assertDeepEquals({{foo = 3, bar = 5}, {foo = 1, bar = 9}}, Template.retrieveReturnValues('Foo'))
end

function suite:testStashValueRetrieve()
	Template.stashReturnValue({foo = 3, bar = 5}, 'Foo')
	self:assertDeepEquals({}, Template.retrieveReturnValues('Bar'))
	self:assertDeepEquals({{foo = 3, bar = 5}}, Template.retrieveReturnValues('Foo'))
	self:assertDeepEquals({}, Template.retrieveReturnValues('Foo'))
	Template.stashReturnValue({foo = 3, bar = 5}, 'Foo')
	Template.stashReturnValue({foo = 1, bar = 9}, 'Foo')
	Template.stashReturnValue(7, 'Foo')
	self:assertDeepEquals({{foo = 3, bar = 5}, {foo = 1, bar = 9}, 7}, Template.retrieveReturnValues('Foo'))
end

return suite
