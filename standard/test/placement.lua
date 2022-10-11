---
-- @Liquipedia
-- wiki=commons
-- page=Module:Placement/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Placement = Lua.import('Module:Placement', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

local NON_BREAKING_SPACE = '&nbsp;'
local ZERO_WIDTH_SPACE = '&#8203;'
local EN_DASH = '–'

function suite:testRangeLabel()
	local DASH = ZERO_WIDTH_SPACE .. EN_DASH .. ZERO_WIDTH_SPACE
	self:assertEquals(('1st' .. DASH .. '2nd'), Placement.RangeLabel{1, 2})
	self:assertEquals('1st', Placement.RangeLabel{1, 1})
end

function suite:testGetBgClass()
	self:assertEquals(nil, Placement.getBgClass('DummyDummy'))
	self:assertEquals('background-color-first-place', Placement.getBgClass(1))
	self:assertEquals('bg-dq', Placement.getBgClass('dq'))
end

function suite:testGet()
	local DASH = NON_BREAKING_SPACE .. '-' .. NON_BREAKING_SPACE
	self:assertEquals(
		'class="text-center placement-1" data-sort-value="1"|<b class="placement-text">1st</b>',
		Placement.get('1')
	)
	self:assertEquals(
		'class="text-center placement-draw" data-sort-value="3-4"|<b class="placement-text">3rd' .. DASH .. '4th</b>',
		Placement.get('3-4')
	)
	self:assertEquals(
		'class="text-center placement-dnp" data-sort-value="1032"|<b>hi</b>',
		Placement.get('dnp', 'hi')
	)
end

return suite
