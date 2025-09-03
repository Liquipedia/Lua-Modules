--- Triple Comment to Enable our LLS Plugin
local WarningBox = require('Module:Widget/WarningBox')

describe('WarningBox.display', function()
	it('should return correct HTML for string input', function()
		local text = "Warning: This is a test"
		local result = tostring(WarningBox{text = text})
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">Warning: This is a test</td>' ..
			'</tr></table></div>'
		assert.are.equal(expected, result)
	end)

	it('should return correct HTML for number input', function()
		local text = 12345
		local result = tostring(WarningBox{text = text})
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">12345</td></tr></table></div>'
		assert.are.equal(expected, result)
	end)
end)
