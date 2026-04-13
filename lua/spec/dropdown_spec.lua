local Lua = require('Module:Lua')
local Dropdown = Lua.import('Module:Widget/Basic/Dropdown/Container')
local DropdownItem = Lua.import('Module:Widget/Basic/Dropdown/Item')

describe('Dropdown', function()
	it('should render a basic dropdown wrapper', function()
		local widget = Dropdown{
			label = 'Click me',
			children = 'Menu children'
		}
		local html = tostring(widget)
		assert.truthy(html:find('dropdown%-widget'))
		assert.truthy(html:find('dropdown%-widget%-%-form'))
		assert.truthy(html:find('dropdown%-widget__toggle'))
		assert.truthy(html:find('data%-dropdown%-toggle="true"'))
		assert.truthy(html:find('dropdown%-widget__menu'))
		assert.truthy(html:find('dropdown%-widget__label'))
		assert.truthy(html:find('dropdown%-widget__indicator'))
		assert.truthy(html:find('btn%-secondary'))
	end)

	it('should render dropdown items', function()
		local widget = Dropdown{
			label = 'Actions',
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

	it('should render the default form variant with built-in toggle structure', function()
		local widget = Dropdown{
			classes = {'custom-dropdown'},
			prefix = 'Icon',
			label = 'Choose option',
			children = {
				DropdownItem{children = 'Option 1'},
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('dropdown%-widget%-%-form'))
		assert.truthy(html:find('custom%-dropdown'))
		assert.truthy(html:find('btn%-secondary'))
		assert.truthy(html:find('Choose option'))
		assert.truthy(html:find('aria%-haspopup="menu"'))
		assert.truthy(html:find('aria%-hidden="true"'))
		assert.truthy(html:find('dropdown%-widget__prefix'))
		assert.truthy(html:find('dropdown%-widget__label'))
		assert.truthy(html:find('dropdown%-widget__indicator'))
		assert.truthy(html:find('dropdown%-widget__item'))
	end)

	it('should render dropdown items with icons using fontawesome icon names', function()
		local widget = Dropdown{
			label = 'Menu',
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
			label = 'External',
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
			label = 'Actions',
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

	it('should render the inline variant with built-in toggle structure', function()
		local widget = Dropdown{
			variant = 'inline',
			prefix = 'Icon',
			label = 'Actions',
			children = {
				DropdownItem{children = 'Option 1'},
			}
		}
		local html = tostring(widget)
		assert.truthy(html:find('dropdown%-widget%-%-inline'))
		assert.truthy(html:find('btn%-ghost'))
		assert.truthy(html:find('dropdown%-widget__prefix'))
		assert.truthy(html:find('dropdown%-widget__label'))
		assert.truthy(html:find('dropdown%-widget__indicator'))
		assert.truthy(html:find('aria%-haspopup="menu"'))
		assert.truthy(html:find('aria%-hidden="true"'))
	end)
end)
