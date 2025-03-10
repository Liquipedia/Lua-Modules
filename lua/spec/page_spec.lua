--- Triple Comment to Enable our LLS Plugin
describe('Page', function()
	local Page = require('Module:Page')

	local orig = mw.title.new
	before_each(function()
		mw.title.new = spy.new(function(page)
			if page == 'https://google.com' then
				return nil
			end
			return {exists = page == 'Module:Page'}
		end)
	end)
	after_each(function()
		mw.title.new = orig
	end)

	describe('exists', function()
		it('verify', function()
			assert.is_false(Page.exists('https://google.com'))
			assert.is_false(Page.exists('PageThatDoesntExistPlx'))
			assert.is_true(Page.exists('Module:Page'))
		end)
	end)

	describe('internal link', function()
		it('verify', function()
			assert.are_equal('[[Module:Page|Module:Page]]', Page.makeInternalLink('Module:Page'))
			assert.are_equal('[[Module:Page|DisplayText]]', Page.makeInternalLink('DisplayText', 'Module:Page'))
			assert.are_equal('[[Module:Page|DisplayText]]', Page.makeInternalLink({}, 'DisplayText', 'Module:Page'))
			assert.is_nil(
				Page.makeInternalLink({onlyIfExists = true}, 'DisplayText', 'Module:PageThatDoesntExistPlx')
			)
			assert.are_equal(
				'[[Module:Page|DisplayText]]',
				Page.makeInternalLink({onlyIfExists = true}, 'DisplayText', 'Module:Page')
			)
			assert.is_nil(Page.makeInternalLink({}))
		end)
	end)

	describe('external link', function()
		it('verify', function()
			assert.is_nil(Page.makeExternalLink('Display', ''))
			assert.is_nil(Page.makeExternalLink('', 'https://google.com'))
			assert.are_equal('[https://google.com Display Text]',
				Page.makeExternalLink('Display Text', 'https://google.com'))
		end)
	end)
end)
