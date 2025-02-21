--- Triple Comment to Enable our LLS Plugin
local WarningBox = require('Module:WarningBox')

describe('WarningBox.display', function()
	it('should return correct HTML for string input', function()
		local text = "Warning: This is a test"
		local result = tostring(WarningBox.display(text))
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">Warning: This is a test</td>' ..
			'</tr></table></div>'
		assert.are.equal(expected, result)
	end)

	it('should return correct HTML for number input', function()
		local text = 12345
		local result = tostring(WarningBox.display(text))
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">12345</td></tr></table></div>'
		assert.are.equal(expected, result)
	end)
end)

describe('WarningBox.displayAll', function()
	it('should return correct HTML for array of strings', function()
		local arr = {"Warning 1", "Warning 2"}
		local result = tostring(WarningBox.displayAll(arr))
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">Warning 1</td></tr></table></div>' ..
			'<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">Warning 2</td></tr></table></div>'
		assert.are.equal(expected, result)
	end)

	it('should return correct HTML for array of numbers', function()
		local arr = {123, 456}
		local result = tostring(WarningBox.displayAll(arr))
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">123</td></tr></table></div>' ..
			'<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">456</td></tr></table></div>'
		assert.are.equal(expected, result)
	end)

	it('should return correct HTML for mixed array of strings and numbers', function()
		local arr = {"Warning 1", 456}
		local result = tostring(WarningBox.displayAll(arr))
		local expected = '<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">Warning 1</td></tr></table></div>' ..
			'<div class="show-when-logged-in navigation-not-searchable ambox-wrapper ambox ' ..
			'wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red"><table><tr><td class="ambox-image">' ..
			'[[File:Emblem-important.svg|40px|link=]]</td><td class="ambox-text">456</td></tr></table></div>'
		assert.are.equal(expected, result)
	end)
end)
