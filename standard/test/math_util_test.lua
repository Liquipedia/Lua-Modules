---
-- @Liquipedia
-- wiki=commons
-- page=Module:MathUtil/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local MathUtil = Lua.import('Module:MathUtil', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testIlog2()
	self:assertEquals(3, MathUtil.ilog2(8))
	self:assertEquals(4, MathUtil.ilog2(24))
end

function suite:testSum()
	self:assertEquals(12, MathUtil.sum{3, 5, 4})
	self:assertEquals(0, MathUtil.sum{})
end

function suite:testPartialSums()
	self:assertDeepEquals({0, 3, 8, 12}, MathUtil.partialSums{3, 5, 4})
	self:assertDeepEquals({0}, MathUtil.partialSums{})
end

function suite:testDotProduct()
	self:assertEquals(55, MathUtil.dotProduct({3, 2, 4}, {5, 6, 7}))
end

return suite
