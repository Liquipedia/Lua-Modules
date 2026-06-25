--- Triple Comment to Enable our LLS Plugin
describe('PagePreview', function()
	local PagePreview = require('Module:PagePreview')

	describe('key', function()
		it('normalizes spaces to underscores', function()
			assert.are_equal('Some_Player', PagePreview.key('Some Player'))
			assert.are_equal('Supr', PagePreview.key('Supr'))
		end)
	end)

	describe('parseCard', function()
		it('maps a full player row to a compact card', function()
			local card = PagePreview.parseCard({
				pagename = 'Supr',
				id = 'supr',
				name = 'Seth Hoffman',
				nationality = 'United States',
				teampagename = 'Soniqs',
				birthdate = '1995-05-10',
				deathdate = '',
				earnings = '74410',
				imageurl = 'https&#58;//liquipedia.net/commons/images/thumb/a/ab/Soniqs_Supr.jpg/320px-Soniqs_Supr.jpg',
				extradata = { role = 'igl' },
			})
			assert.are_equal('Supr', card.page)
			assert.are_equal('player', card.type)
			assert.are_equal('supr', card.name)
			assert.are_equal('Seth Hoffman', card.realName)
			assert.are_equal('United States', card.flag)
			assert.are_equal('Soniqs', card.team) -- prettified from teampagename
			assert.are_equal('In-game leader', card.role) -- mapped from 'igl'
			assert.is_nil(card.status)
			assert.are_equal(74410, card.earnings)
			assert.are_equal(
				'https://liquipedia.net/commons/images/thumb/a/ab/Soniqs_Supr.jpg/320px-Soniqs_Supr.jpg',
				card.image
			)
			-- born string is infobox-style, &nbsp; normalized to a plain space; age varies by run date
			assert.is_truthy(card.born:find('May 10, 1995', 1, true))
			assert.is_truthy(card.born:find('(age ', 1, true))
		end)

		it('falls back to name when id is empty and tolerates missing fields', function()
			assert.are_same({
				page = 'Foo',
				type = 'player',
				name = 'Real Name',
				realName = 'Real Name',
				flag = nil,
				born = nil,
				team = nil,
				role = nil,
				status = nil,
				earnings = nil,
				image = nil,
			}, PagePreview.parseCard({ pagename = 'Foo', name = 'Real Name', extradata = {} }))
		end)

		it('keeps an unmapped role code as-is', function()
			local card = PagePreview.parseCard({ pagename = 'Foo', name = 'N', extradata = { role = 'flex' } })
			assert.are_equal('flex', card.role)
		end)
	end)

	describe('extra wiki fields', function()
		it('resolves column and extradata specs into labelled rows', function()
			local card = PagePreview.parseCard({
				pagename = 'Foo',
				name = 'N',
				region = 'Europe',
				extradata = { agent1 = 'Fade', agent2 = 'Sova' },
			}, {
				{ label = 'Region', column = 'region' },
				{ label = 'Agents', extradata = { 'agent1', 'agent2' } },
			})
			assert.are_same({
				{ label = 'Region', value = 'Europe' },
				{ label = 'Agents', value = 'Fade, Sova' },
			}, card.extra)
		end)

		it('omits fields with no value and yields nil extra when none resolve', function()
			local card = PagePreview.parseCard({ pagename = 'Foo', name = 'N', extradata = {} }, {
				{ label = 'Region', column = 'region' },
				{ label = 'Agents', extradata = { 'agent1' } },
			})
			assert.is_nil(card.extra)
		end)

		it('rejects unsafe column names from the query', function()
			assert.are_same({ 'region' }, PagePreview.extraColumns({
				{ label = 'Region', column = 'region' },
				{ label = 'Bad', column = 'region; DROP TABLE' },
				{ label = 'Dup name', column = 'name' }, -- already a generic column
			}))
		end)
	end)

	describe('collectedKeys', function()
		before_each(function() PagePreview.reset() end)
		after_each(function() PagePreview.reset() end)

		it('normalizes, dedups, and preserves first-seen order', function()
			PagePreview.register('Some Player')
			PagePreview.register('Some Player')
			PagePreview.register('Other Guy')
			assert.are_same({ 'Some_Player', 'Other_Guy' }, PagePreview.collectedKeys())
		end)

		it('caps the accumulator at MAX_ENTITIES distinct keys', function()
			for i = 1, 150 do
				PagePreview.register('Player' .. i)
			end
			assert.are_equal(100, #PagePreview.collectedKeys())
		end)
	end)

	describe('register + flush', function()
		local mockLpdb = require('Module:Mock/Lpdb')

		before_each(function()
			PagePreview.reset()
			mockLpdb.setUp()
		end)

		after_each(function()
			mockLpdb.tearDown()
			PagePreview.reset()
		end)

		it('emits nothing when no links were registered', function()
			assert.are_equal('', PagePreview.flush())
		end)

		it('collectCards returns cards keyed by normalized pagename, deduped', function()
			PagePreview.register('Supr')
			PagePreview.register('Supr') -- dedup
			local cards = PagePreview.collectCards()
			assert.are_equal('supr', cards.Supr.name)
			assert.are_equal('player', cards.Supr.type)
		end)

		it('flush wraps the data in a hidden island element (never a <script>)', function()
			PagePreview.register('Supr')
			local html = PagePreview.flush()
			assert.is_truthy(html:find('id="page-preview-data"', 1, true))
			assert.is_truthy(html:find('data-preview=', 1, true))
			assert.is_nil(html:find('<script', 1, true))
		end)

		it('ignores empty page names', function()
			PagePreview.register(nil)
			PagePreview.register('')
			assert.are_equal('', PagePreview.flush())
			assert.are_same({}, PagePreview.collectCards())
		end)
	end)
end)
