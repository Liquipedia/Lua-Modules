-- luacheck: ignore
--- Triple Comment to Enable our LLS Plugin
describe('ProfileTabs Controller', function()
	local Controller = require('Module:Features/ProfileTabs/Controller')
	local ProfileTabsTabs = require('Module:Features/ProfileTabs/Components/Tabs')
	local Page = require('Module:Page')
	local mockLpdb = require('Module:Mock/Lpdb')

	local ProfileTabs = Controller
	ProfileTabs.getTabArgs = ProfileTabsTabs.getTabArgs
	ProfileTabs.getSubpageName = Controller._getSubpageName

	local function expectedMediawikiUrl(mediawikiForm, template, queryArg, profile)
		return tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. mediawikiForm,
			{[template .. '[' .. queryArg .. ']'] = profile}
		)):gsub(' ', '%%20')
	end

	local function expectedPlayerH2HUrl(profile)
		return expectedMediawikiUrl('Match history', 'Head_to_head_query', 'player', profile)
	end

	local origTitleNew
	local titleStub
	before_each(function()
		origTitleNew = mw.title.new
	end)
	after_each(function()
		mw.title.new = origTitleNew
		if titleStub then
			titleStub:revert()
			titleStub = nil
		end
	end)

	local function withExistingPages(existingPages, func)
		local existing = {}
		for _, page in ipairs(existingPages) do
			existing[page] = true
		end
		---@diagnostic disable-next-line: duplicate-set-field
		mw.title.new = function(page)
			return {exists = existing[page] == true}
		end
		return func()
	end

	local function withH2HVariable(func)
		mw.ext.VariablesLua.vardefine('h2h', 'true')
		return func()
	end

	describe('_getSubpageName', function()
		it('should return the subpage tab name', function()
			assert.are.equal('Results', ProfileTabs.getSubpageName('player', 'NoSuchProfile/Results'))
			assert.are.equal('Played Matches', ProfileTabs.getSubpageName('player', 'NoSuchProfile/Played Matches'))
		end)

		it('should return nil on the profile main page', function()
			assert.is_nil(ProfileTabs.getSubpageName('player', 'NoSuchProfile'))
		end)

		it('should return nil for unknown subpages', function()
			assert.is_nil(ProfileTabs.getSubpageName('player', 'NoSuchProfile/Bogus'))
		end)
	end)

	describe('run', function()
		it('should render the tabs on a subpage', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile/Results'}
			end)
			withExistingPages({'NoSuchProfile/Results', 'NoSuchProfile/Awards'}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('NoSuchProfile/Results', nil, true) ~= nil)
				assert.is_true(html:find('NoSuchProfile/Awards', nil, true) ~= nil)
			end)
		end)

		it('should override the page display title without changing the player name', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile/Results'}
			end)
			withExistingPages({'NoSuchProfile/Results'}, function()
				local result = ProfileTabs.run({displayTitle = 'Custom Title'})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('NoSuchProfile/Results', nil, true) ~= nil)
			end)
		end)

		it('should use a custom displayTitle string as the page title', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile/Results'}
			end)
			withExistingPages({'NoSuchProfile/Results'}, function()
				local setTitleProps
				stub(Page, 'setDisplayTitle', function(props)
					setTitleProps = props
				end)
				local result = ProfileTabs.run({displayTitle = 'Custom Title'})
				assert.is_not_nil(result)
				assert.are.equal('Custom Title', setTitleProps.title)
			end)
		end)

		it('should not set the auto display title when displayTitle is false', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile/Results'}
			end)
			withExistingPages({'NoSuchProfile/Results'}, function()
				local setTitleProps
				stub(Page, 'setDisplayTitle', function(props)
					setTitleProps = props
				end)
				local result = ProfileTabs.run({displayTitle = 'false'})
				assert.is_not_nil(result)
				-- No automatic "NoSuchProfile: Results" title is set
				assert.is_nil(setTitleProps.title)
			end)
		end)

		it('should render on the main page without subpage tabs', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile'}
			end)
			withExistingPages({}, function()
				local result = ProfileTabs.run({})
				assert.is_not_nil(result)
				local html = tostring(result)
				assert.is_true(html:find('NoSuchProfile', nil, true) ~= nil)
			end)
		end)

		it('should render the Head to head tab as a clickable query link', function()
			mockLpdb.setUp()
			titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {prefixedText = 'NoSuchProfile/Results'}
			end)
			withExistingPages({'NoSuchProfile/Results'}, function()
				withH2HVariable(function()
					local result = ProfileTabs.run({})
					local html = tostring(result)
					assert.is_true(html:find(expectedPlayerH2HUrl('NoSuchProfile'), nil, true) ~= nil)
					assert.is_true(html:find('Head to head', nil, true) ~= nil)
				end)
			end)
		end)

		it('_getDisplayTitle should return proper display titles', function()
			mockLpdb.setUp()
			assert.is_nil(ProfileTabs._getDisplayTitle('player', 'NoSuchProfile', nil))
			assert.is_not_nil(ProfileTabs._getDisplayTitle('player', 'NoSuchProfile', 'Results'))
			local title = ProfileTabs._getDisplayTitle('player', 'NoSuchProfile', 'Results')
			assert.is_not_nil(title and title:find('Results', nil, true))
		end)

		describe('target parameter', function()
			it('should resolve team from the template target arg', function()
				assert.are.equal('team', ProfileTabs._resolveProfileType({target = 'team'}))
			end)

			it('should fall back to player when target is unknown', function()
				assert.are.equal('player', ProfileTabs._resolveProfileType({target = 'bogus'}))
			end)

			it('should fall back to player when target is missing', function()
				assert.are.equal('player', ProfileTabs._resolveProfileType({}))
			end)

			it('should use the team tabs when running with target=team', function()
				mockLpdb.setUp()
				titleStub = stub(mw.title, 'getCurrentTitle', function()
					return {prefixedText = 'NoSuchProfile'}
				end)
				withExistingPages({'NoSuchProfile/Player Results', 'NoSuchProfile/Coaching'}, function()
					local result = ProfileTabs.run({target = 'team'})
					assert.is_not_nil(result)
					local html = tostring(result)
					-- 'Player Results' is part of the team tab list, 'Coaching' only of the player one
					assert.is_true(html:find('NoSuchProfile/Player Results', nil, true) ~= nil)
					assert.is_nil(html:find('NoSuchProfile/Coaching', nil, true))
				end)
			end)
		end)
	end)
end)

