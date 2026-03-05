--- Triple Comment to Enable our LLS Plugin
describe('timezone', function()
	local Timezone = require('Module:Timezone')

	describe('get tz string', function()
		it('check', function()
			assert.are_equal(
				'<abbr data-tz="+05:30" title="Indian Standard Time (UTC+5:30)">IST</abbr>',
				Timezone.getTimezoneString{timezone = 'IST'}
			)
			assert.are_equal(
				'<abbr data-tz="+02:00" title="Central European Summer Time (UTC+2)">CEST</abbr>',
				Timezone.getTimezoneString{timezone = 'CEST'}
			)
			assert.is_nil(
				Timezone.getTimezoneString{timezone = 'DUMMY'}
			)
		end)
	end)

	describe('get offset', function()
		it('check', function()
			assert.are_equal(
				5 * 60 * 60 + 30 * 60,
				Timezone.getOffset{timezone = 'IST'}
			)
			assert.are_equal(
				2 * 60 * 60,
				Timezone.getOffset{timezone = 'CEST'}
			)
			assert.is_nil(
				Timezone.getOffset{timezone = 'DUMMY'}
			)
		end)
	end)

	describe('get timezone data', function()
		it('check', function()
			assert.are_same(
				{
					abbr = 'IST',
					name = 'Indian Standard Time',
					offset = {5, 30},
				},
				Timezone.getTimezoneData('IST')
			)
			assert.are_same(
				{
					abbr = 'CEST',
					name = 'Central European Summer Time',
					offset = {2, 0},
				},
				Timezone.getTimezoneData('CEST')
			)
			assert.are_same(
				{
					abbr = 'CEST',
					name = 'Central European Summer Time',
					offset = {2, 0},
				},
				Timezone.getTimezoneData('cest')
			)
			assert.is_nil(
				Timezone.getTimezoneData('DUMMY')
			)
			assert.is_nil(
				Timezone.getTimezoneData(nil)
			)
		end)
	end)
end)
