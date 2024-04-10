--- Triple Comment to Enable our LLS Plugin
describe('Squad', function()
	local Squad = require('Module:Squad')
	local SquadRow = require('Module:Squad/Row')

	describe('row', function()
		local LpdbSquadStub, LpdbQueryStub

		before_each(function()
			LpdbSquadStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
			LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		end)

		after_each(function()
			LpdbSquadStub:revert()
			LpdbQueryStub:revert()
		end)

		it('displays correct and stores correctly', function()
			local row = SquadRow()
			row:id{'Baz', 'se'}
					:name{name = 'Foo Bar'}
					:status(2)
					:role{}
					:date('2022-01-01', 'Join Date:&nbsp;', 'joindate')
					:date('2022-03-03', 'Inactive Date:&nbsp;', 'inactivedate')
					:date('2022-05-01', 'Leave Date:&nbsp;', 'leavedate')

			GoldenTest('squad_row', tostring(row:create():tryMake()[1]))

			assert.stub(LpdbSquadStub).was.called_with('Baz_2022-01-01__former', {
				id = 'Baz',
				inactivedate = '2022-03-03',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				link = 'Baz',
				name = 'Foo Bar',
				nationality = '',
				type = 'player',
				newteam = '',
				newteamtemplate = '',
				position = '',
				role = '',
				status = 'former',
				teamtemplate = '',
				extradata = {},
			})
		end)
	end)

	describe('header', function()
		GoldenTest('squad_header', tostring(Squad({}):init{}:title():header():create()))
	end)
end)
