--- Triple Comment to Enable our LLS Plugin
describe('hidden data box', function()
	local Hdb = require('Module:HiddenDataBox')
	local Logic = require('Module:Logic')
	local Variables = require('Module:Variables')
	local WarningBox = require('Module:WarningBox')

	describe('tier parseing', function()
		it('empty tier return nil', function()
			assert.is_nil(Hdb.validateTier())
		end)
		it('valid tier', function()
			assert.are_equal('1', Hdb.validateTier('1'))
		end)
		it('valid tiertype', function()
			local _, tierType = Hdb.validateTier(nil, 'Qualifier')
			assert.are_equal('Qualifier', tierType)
		end)

		it('unknown tier', function()
			local _, _, warnings = Hdb.validateTier('Qualifier')
			assert.are_same({'Qualifier is not a known Liquipedia Tier[[Category:Pages with invalid Tier]]'}, warnings)
		end)

		it('unknown tiertype', function()
			local _, _, warnings = Hdb.validateTier(nil, 'Abc')
			assert.are_same({'Abc is not a known Liquipedia Tiertype[[Category:Pages with invalid Tiertype]]'}, warnings)
		end)
	end)

	describe('missing parents', function()
		local LpdbQueryStub
		before_each(function ()
			LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		end)

		after_each(function ()
			LpdbQueryStub:revert()
		end)

		it('has correct warning', function()
			assert.are_same(
				tostring(WarningBox.display('DummyPage is not a Liquipedia Tournament[[Category:Pages with invalid parent]]')),
				tostring(Hdb.run({parent = 'DummyPage'}))
			)
		end)
	end)

	describe('test fetching and wiki var storing', function()
		local LpdbQueryStub
		before_each(function ()
			LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', function(tbl)
				if tbl == 'tournament' then
					return {
						require('test_assets.lpdb_tournament')[2]
					}
				elseif tbl == 'placement' then
					return {
						require('test_assets.lpdb_placement')[18]
					}
				end
			end)
		end)

		after_each(function ()
			LpdbQueryStub:revert()
		end)

		it('no warnings', function()
			assert.is_true(Logic.isEmpty(tostring(Hdb.run{parent = 'Six_Lounge_Series/4'})))
		end)

		it('tournament wiki variables are correctly set', function()
			Hdb.run{parent = 'Six_Lounge_Series/4'}
			assert.are_equal('Six_Lounge_Series/4', Variables.varDefault('tournament_parent'))
			assert.are_equal('Six Lounge Series #4 - Finals', Variables.varDefault('tournament_name'))
			assert.are_equal('2017-12-17', Variables.varDefault('tournament_startdate'))
		end)

		it('player wiki variables are correctly set', function()
			Hdb.run{parent = 'Six_Lounge_Series/4'}
			assert.are_equal('Xy_G', Variables.varDefault('BUTEO eSports_p5'))
			assert.are_equal('xy_G', Variables.varDefault('BUTEO eSports_p5dn'))
			assert.are_equal('Germany', Variables.varDefault('BUTEO eSports_p5flag'))
		end)
	end)
end)
