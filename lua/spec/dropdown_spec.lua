local Lua = require('Module:Lua')
local Dropdown = Lua.import('Module:Widget/Basic/Dropdown/Container')
local DropdownItem = Lua.import('Module:Widget/Basic/Dropdown/Item')

describe('Dropdown', function()
	it('should render a basic dropdown wrapper', function()
		local widget = Dropdown{
			button = 'Click me',
			children = 'Menu children'
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
			children = {
				DropdownItem{children = 'Option 1'},
				DropdownItem{children = 'Option 2', link = 'TargetPage'}
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('Option 1'))
		assert.truthy(html:find('Option 2'))
		assert.truthy(html:find('dropdown%-widget__item'))
	end)

	it('should render the form variant with forwarded classes and attributes', function()
		local widget = Dropdown{
			variant = 'form',
			classes = {'custom-dropdown'},
			buttonClasses = {'custom-toggle'},
			menuClasses = {'custom-menu'},
			buttonSize = 'md',
			prefix = 'Icon',
			label = 'Choose option',
			prefixClasses = {'custom-prefix'},
			labelClasses = {'custom-label'},
			children = {
				DropdownItem{children = 'Option 1'},
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('dropdown%-widget%-%-form'))
		assert.truthy(html:find('custom%-dropdown'))
		assert.truthy(html:find('custom%-toggle'))
		assert.truthy(html:find('custom%-prefix'))
		assert.truthy(html:find('custom%-label'))
		assert.truthy(html:find('custom%-menu'))
		assert.truthy(html:find('aria%-haspopup="menu"'))
		assert.truthy(html:find('aria%-hidden="true"'))
		assert.truthy(html:find('dropdown%-widget__prefix'))
		assert.truthy(html:find('dropdown%-widget__label'))
		assert.truthy(html:find('dropdown%-widget__indicator'))
		assert.truthy(html:find('dropdown%-widget__item'))
	end)

	it('should render dropdown items with icons using fontawesome icon names', function()
		local widget = Dropdown{
			button = 'Menu',
			children = {
				DropdownItem{
					children = 'Home',
					icon = 'projecthome'
				}
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('fa%-home'))
	end)

	it('should render dropdown items with external links', function()
		local widget = Dropdown{
			button = 'External',
			children = {
				DropdownItem{
					children = 'External Link',
					link = 'https://liquipedia.net',
					linktype = 'external'
				}
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('External Link'))
		assert.truthy(html:find('https://liquipedia.net'))
	end)

	it('should render dropdown items with attributes', function()
		local widget = Dropdown{
			button = 'Actions',
			children = {
				DropdownItem{
					children = 'Action',
					attributes = {['data-action'] = 'test'}
				}
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('data%-action="test"'))
	end)
end)
