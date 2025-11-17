---
-- @Liquipedia
-- page=Module:Template/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Template = Lua.import('Module:Template')

local suite = ScribuntoUnit:new()

local SE_FLAG = '<span class="flag">[[File:Se hd.png|Sweden|link=:Category:Sweden]]</span>'

function suite:testSafeExpand()
	local frame = mw.getCurrentFrame()
	self:assertEquals('[[Template:PageThatsDead]]', Template.safeExpand(frame, 'PageThatsDead'))
	self:assertEquals(SE_FLAG, Template.safeExpand(frame, 'Flag/se', {}))
end

function suite:testExpandTemplate()
	local frame = mw.getCurrentFrame()
	local fn = function() return Template.expandTemplate(frame, 'PageThatsDead') end
	self:assertThrows(fn)
	self:assertEquals(SE_FLAG, Template.expandTemplate(frame, 'Flag/se', {}))
end

function suite:testStashArgsRetrieve()
	---@diagnostic disable-next-line: missing-fields
	Template.stashArgs{foo = 3, bar = 5, namespace = 'Foo'}
	self:assertDeepEquals({}, Template.retrieveReturnValues('Bar'))
	self:assertDeepEquals({{foo = 3, bar = 5}}, Template.retrieveReturnValues('Foo'))
	self:assertDeepEquals({}, Template.retrieveReturnValues('Foo'))
	---@diagnostic disable-next-line: missing-fields
	Template.stashArgs{foo = 3, bar = 5, namespace = 'Foo'}
	---@diagnostic disable-next-line: missing-fields
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
