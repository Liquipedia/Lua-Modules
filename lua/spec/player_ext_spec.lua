--- Triple Comment to Enable our LLS Plugin
describe('PlayerExt', function()
	local PlayerExt = require('Module:Player/Ext')

	describe('is party', function()
		local mockLpdb = require('Module:Mock/Lpdb')

		---@param pageName string
		---@return player
		local getDataFor = function(pageName)
			mockLpdb.setUp()
			local data = mw.ext.LiquipediaDB.lpdb('player', {
				limit = 1,
				conditions = '[[pagename::' .. pageName .. ']]',
			})[1]
			mockLpdb.tearDown()
			return data
		end

		it('check', function()
			assert.is_nil(PlayerExt.fromLpdbPlayerRecord())
			assert.is_nil(PlayerExt.fromLpdbPlayerRecord{})

			assert.are_same({
					pageName = 'Supr',
					displayName = 'supr',
					flag = 'United States',
					faction = nil,
					team = 'soniqs 2021',
					extradata = {
						role = 'In-game leader',
						role2 = 'Support',
						signatureOperator1 = 'smoke',
						signatureOperator2 = 'gridlock',
					},
					pageIsResolved = true,
					apiId = nil,
			}, PlayerExt.fromLpdbPlayerRecord(getDataFor('Supr')))

			assert.are_same({
					pageName = 'Clem',
					displayName = 'Clem',
					flag = 'France',
					faction = 'Terran',
					team = 'team liquid 2024',
					extradata = {
						firstname = 'Clément',
						faction = 'Terran',
						lastname = 'Desplanches',
						roles = {},
					},
					pageIsResolved = true,
					apiId = nil,
			}, PlayerExt.fromLpdbPlayerRecord(getDataFor('Clem')))
		end)
	end)
end)
