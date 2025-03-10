--- Triple Comment to Enable our LLS Plugin
local Tabs = require('Module:Tabs')

describe('Tabs Module', function()
	describe('Tabs.static', function()
		it('should error when no arguments are provided', function()
			assert.is.error(Tabs.static, 'You are trying to add a "Tabs" template without arguments for names nor links')
		end)

		it('should create static tabs with valid arguments', function()
			local args = {
				name1 = 'Tab1',
				link1 = 'Link1',
				name2 = 'Tab2',
				link2 = 'Link2',
				This = 1
			}
			local result = Tabs.static(args)
			assert.is_not_nil(result)
			assert.is_true(tostring(result):find('class="nav nav-tabs navigation-not-searchable tabs tabs2"', nil, true) ~= nil)
		end)
	end)

	describe('Tabs.dynamic', function()
		it('should return nil when no arguments are provided', function()
			assert.is.error(Tabs.dynamic, 'You are trying to add a "Tabs" template without arguments for names nor links')
		end)

		it('should create dynamic tabs with valid arguments', function()
			local args = {
				name1 = 'Tab1',
				content1 = 'Content1',
				name2 = 'Tab2',
				content2 = 'Content2',
				This = 1
			}
			local result = Tabs.dynamic(args)
			assert.is_not_nil(result)
			assert.is_true(tostring(result):find('class="nav nav-tabs tabs tabs2"', nil, true) ~= nil)
		end)

		it('should return single tab content when only one tab is provided', function()
			local args = {
				name1 = 'Tab1',
				content1 = 'Content1',
				This = 1
			}
			local result = Tabs.dynamic(args)
			assert.is_not_nil(result)
			assert.is_true(tostring(result):find('Content1', nil, true) ~= nil)
		end)
	end)

	describe('Tabs._readArguments', function()
		it('should read arguments correctly', function()
			local args = {
				name1 = 'Tab1',
				link1 = 'Link1',
				content1 = 'Content1',
				name2 = 'Tab2',
				link2 = 'Link2',
				content2 = 'Content2',
				This = 1
			}
			local options = {allowThis2 = true}
			local result = Tabs._readArguments(args, options)
			assert.are.equal(2, #result)
			assert.are.equal('Tab1', result[1].name)
			assert.are.equal('Link1', result[1].link)
			assert.are.equal('Content1', result[1].content)
			assert.is_true(result[1].this)
		end)
	end)

	describe('Tabs._setThis', function()
		it('should set the correct tab as active', function()
			local tabArgs = {
				{name = 'Tab1', link = 'FakePage', this = false},
				{name = 'Tab2', link = 'FakePage2', this = false}
			}
			Tabs._setThis(tabArgs)
			assert.is_true(tabArgs[1].this)
			assert.is_false(tabArgs[2].this)
		end)
	end)

	describe('Tabs._buildContentDiv', function()
		it('should build content div correctly', function()
			local result = tostring(Tabs._buildContentDiv(true, false, false))
			assert.is_true(result:find('"tabs-content"', nil, true) ~= nil)
		end)
	end)
end)
