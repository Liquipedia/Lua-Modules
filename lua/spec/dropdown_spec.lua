local Lua = require('Module:Lua')
local Dropdown = Lua.import('Module:Widget/Basic/Dropdown')
local DropdownItem = Lua.import('Module:Widget/Basic/DropdownItem')

describe('Dropdown', function()
	it('should render a basic dropdown wrapper', function()
		local widget = Dropdown{
			button = 'Click me',
			content = 'Menu content'
		}
		local html = tostring(widget)
		assert.truthy(html:find('dropdown%-widget'))
		assert.truthy(html:find('dropdown%-widget__toggle'))
		assert.truthy(html:find('data%-dropdown%-toggle="true"'))
		assert.truthy(html:find('dropdown%-widget__menu'))
	end)

	it('should render dropdown items', function()
		local widget = Dropdown{
			button = 'Actions',
			content = {
				DropdownItem{text = 'Option 1'},
				DropdownItem{text = 'Option 2', link = 'TargetPage'}
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('Option 1'))
		assert.truthy(html:find('Option 2'))
		assert.truthy(html:find('dropdown%-widget__item'))
	end)
end)
