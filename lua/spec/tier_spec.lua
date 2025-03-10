--- Triple Comment to Enable our LLS Plugin
describe('tier', function()
	---@diagnostic disable: param-type-mismatch
	local Tier = require('Module:Tier/Utils')
	local TierData = require('Module:Tier/Data')

	describe('to identifier', function()
		it('check', function()
			assert.are_equal('showmatch', Tier.toIdentifier('ShOW MatCh'))
			assert.are_equal(1, Tier.toIdentifier('1'))
			assert.are_equal(1, Tier.toIdentifier(1))
			assert.is_nil(Tier.toIdentifier(''))
			assert.is_nil(Tier.toIdentifier())
		end)
	end)

	describe('raw', function()
		it('check', function()
			assert.are_same({TierData.tiers[1]}, {Tier.raw(1)})
			assert.are_same({TierData.tiers[1]}, {Tier.raw('1')})
			assert.are_same({TierData.tiers[1], TierData.tierTypes.misc}, {Tier.raw('1', 'misc')})
			assert.are_same({TierData.tiers[1]}, {Tier.raw('1', 'bera')})
			assert.are_same({}, {Tier.raw('bera')})
			assert.are_same({}, {Tier.raw('sedrvo', 'ergbv')})
		end)
	end)

	describe('is valid', function()
		it('check', function()
			assert.is_true(Tier.isValid(1, 'showmatch'))
			assert.is_true(Tier.isValid(1, 'show match'))
			assert.is_true(Tier.isValid(1))
			assert.is_true(Tier.isValid('1', 'showmatch'))
			assert.is_false(Tier.isValid('sedrvo'))
			assert.is_false(Tier.isValid(''))
			assert.is_false(Tier.isValid(1, 'sedrvo'))
			assert.is_true(Tier.isValid(1, ''))
		end)
	end)

	describe('to value', function()
		it('check', function()
			assert.are_same({'1', 'Showmatch'}, {Tier.toValue(1, 'show match')})
			assert.are_same({'1', 'Showmatch'}, {Tier.toValue('1', 'sho wmatch')})
			assert.are_same({'1', 'Showmatch'}, {Tier.toValue(1, 'showmatch')})
			assert.are_same({'1'}, {Tier.toValue(1, 'avberw')})
			assert.are_same({'1'}, {Tier.toValue(1)})
			assert.are_same({}, {Tier.toValue(nil, 'avberw')})
			assert.are_same({}, {Tier.toValue('srntbg', 'avberw')})
		end)
	end)

	describe('to name', function()
		it('check', function()
			assert.are_same({'S-Tier', 'Showmatch'}, {Tier.toName(1, 'showma tch')})
			assert.are_same({'S-Tier'}, {Tier.toName(1)})
			assert.are_same({}, {Tier.toName('sedrvo')})
		end)
	end)

	describe('to short name', function()
		it('check', function()
			assert.are_same({'S', 'Showm.'}, {Tier.toShortName(1, 's howmatch')})
			assert.are_same({'S'}, {Tier.toShortName(1)})
			assert.are_same({}, {Tier.toShortName('sedrvo')})
		end)
	end)

	describe('to category', function()
		it('check', function()
			assert.are_same({'A-Tier Tournaments', 'Miscellaneous Tournaments'}, {Tier.toCategory(2, 'misc')})
			assert.are_same({'A-Tier Tournaments'}, {Tier.toCategory(2)})
			assert.are_same({'A-Tier Tournaments'}, {Tier.toCategory(2, 'dszm')})
			assert.are_same({}, {Tier.toCategory('seatrh')})
		end)
	end)

	describe('sort value', function()
		it('check', function()
			assert.are_equal('A1A9', Tier.toSortValue('1', 'misc'))
			assert.are_equal('A1', Tier.toSortValue('1'))
			assert.error(function() return Tier.toSortValue('abtenr') end)
			assert.error(function() return Tier.toSortValue('abtenr', 'misc') end)
		end)
	end)

	describe('display', function()
		it('check', function()
			-- plain display without any options
			assert.are_equal('Showmatch&nbsp;(S-Tier)', Tier.display(1, 'show MaTcH'))
			assert.are_equal('S-Tier', Tier.display(1))

			-- onlyTierTypeIfBoth option
			assert.are_equal('Showmatch', Tier.display(1, 'show MaTcH', {onlyTierTypeIfBoth = 1}))
			assert.are_equal('S-Tier', Tier.display(1, nil, {onlyTierTypeIfBoth = 1}))

			-- short options
			assert.are_equal('Showmatch&nbsp;(S)', Tier.display(1, 'show MaTcH', {tierShort = 1}))
			assert.are_equal('Showm.&nbsp;(S-Tier)', Tier.display(1, 'show MaTcH', {tierTypeShort = 1}))
			assert.are_equal('Showm.&nbsp;(S)', Tier.display(1, 'show MaTcH', {short = 1}))
			assert.are_equal('Showm.&nbsp;(S)', Tier.display(1, 'show MaTcH', {shortIfBoth = 1}))
			assert.are_equal('S-Tier', Tier.display(1, nil, {shortIfBoth = 1}))

			-- link options
			assert.are_equal('[[S-Tier Tournaments|S-Tier]]', Tier.display(1, nil, {link = 1}))
			assert.are_equal('[[TEST|S-Tier]]', Tier.display(1, nil, {link = 'TEST'}))
			assert.are_equal(
				'[[Showmatches|Showmatch]]' ..
				'&nbsp;' .. '([[S-Tier Tournaments|S-Tier]])',
				Tier.display(1, 'show MaTcH', {link = 1})
			)
			assert.are_equal(
				'[[TEST|Showmatch]]' .. '&nbsp;' .. '([[TEST|S-Tier]])',
				Tier.display(1, 'show MaTcH', {link = 'TEST'})
			)
			assert.are_equal(
				'[[TEST|Showmatch]]' .. '&nbsp;(S-Tier)',
				Tier.display(1, 'show MaTcH', {tierTypeLink = 'TEST'})
			)
			assert.are_equal(
				'[[TEST|Showmatch]]' .. '&nbsp;' .. '([[S-Tier Tournaments|S-Tier]])',
				Tier.display(1, 'show MaTcH', {link = 1, tierTypeLink = 'TEST'})
			)
			assert.are_equal(
				'Showmatch&nbsp;' .. '([[TEST|S-Tier]])',
				Tier.display(1, 'show MaTcH', {tierLink = 'TEST'})
			)
			assert.are_equal(
				'[[Showmatches|Showmatch]]' .. '&nbsp;' .. ('([[TEST|S-Tier]])'),
				Tier.display(1, 'show MaTcH', {link = 1, tierLink = 'TEST'})
			)
		end)
	end)
end)
