---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ordinal/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Ordinal = Lua.import('Module:Ordinal', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testBasicInput()
	self:assertEquals(nil, Ordinal.written())
	self:assertEquals(nil, Ordinal.written(''))
	self:assertEquals(nil, Ordinal.written('foo'))
end

function suite:testWritten()
	self:assertEquals('first', Ordinal.written(1))
	self:assertEquals('second', Ordinal.written(2))
	self:assertEquals('third', Ordinal.written(3))
	self:assertEquals('fourth', Ordinal.written(4))
	self:assertEquals('eighth', Ordinal.written(8))
	self:assertEquals('eleventh', Ordinal.written(11))
	self:assertEquals('twelfth', Ordinal.written(12))
	self:assertEquals('thirteenth', Ordinal.written(13))
	self:assertEquals('twentyfirst', Ordinal.written(21))
	self:assertEquals('fiftieth', Ordinal.written(50))
	self:assertEquals('one hundred first', Ordinal.written(101))
	self:assertEquals('one hundred thirtyfifth', Ordinal.written(135))
	self:assertEquals('One hundred thirtyfifth', Ordinal.written(135, {capitalize = true}))
	self:assertEquals('one-hundred-thirtyfifth', Ordinal.written(135, {hyphenate = true}))
	self:assertEquals('firsts', Ordinal.written(1, {plural = true}))
end

function suite:testOrdinal()
	self:assertEquals('1st', Ordinal._ordinal(1))
	self:assertEquals('2nd', Ordinal._ordinal(2))
	self:assertEquals('3rd', Ordinal._ordinal(3))
	self:assertEquals('4th', Ordinal._ordinal(4))
	self:assertEquals('8th', Ordinal._ordinal(8))
	self:assertEquals('11th', Ordinal._ordinal(11))
	self:assertEquals('12th', Ordinal._ordinal(12))
	self:assertEquals('13th', Ordinal._ordinal(13))
	self:assertEquals('21st', Ordinal._ordinal(21))
	self:assertEquals('101st', Ordinal._ordinal(101))
	self:assertEquals('135th', Ordinal._ordinal(135))
	self:assertEquals('<sup>135th</sup>', Ordinal._ordinal(135, nil, true))
end

return suite
