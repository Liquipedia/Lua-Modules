---
-- @Liquipedia
-- wiki=commons
-- page=Module:Page/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Page = Lua.import('Module:Page', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testExists()
	self:assertFalse(Page.exists('https://google.com'))
	self:assertFalse(Page.exists('PageThatDoesntExistPlx'))
	self:assertTrue(Page.exists('Module:Page'))
end

function suite:testInternalLink()
	self:assertEquals('[[Module:Page|Module:Page]]', Page.makeInternalLink('Module:Page'))
	self:assertEquals('[[Module:Page|DisplayText]]', Page.makeInternalLink('DisplayText', 'Module:Page'))
	self:assertEquals('[[Module:Page|DisplayText]]', Page.makeInternalLink({}, 'DisplayText', 'Module:Page'))
	self:assertEquals(
		nil,
		Page.makeInternalLink({onlyIfExists = true}, 'DisplayText', 'Module:PageThatDoesntExistPlx')
	)
	self:assertEquals(
		'[[Module:Page|DisplayText]]',
		Page.makeInternalLink({onlyIfExists = true}, 'DisplayText', 'Module:Page')
	)
	self:assertEquals(nil, Page.makeInternalLink({}))
end

function suite:testExternalLink()
	self:assertEquals(nil, Page.makeExternalLink('Display', ''))
	self:assertEquals(nil, Page.makeExternalLink('', 'https://google.com'))
	self:assertEquals('[https://google.com Display Text]', Page.makeExternalLink('Display Text', 'https://google.com'))
end

return suite
