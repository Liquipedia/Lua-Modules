--- Triple Comment to Enable our LLS Plugin
describe('Squad', function()
	local Squad = require('Module:Squad')
	local SquadRow = require('Module:Squad/Row')
	local SquadUtils = require('Module:Squad/Utils')

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
			local squadPerson = SquadUtils.readSquadPersonArgs{
				'Baz',
				name = 'Foo Bar',
				joindate = '2022-01-01',
				inactivedate = '2022-03-03',
				leavedate = '2022-05-01',
				status = SquadUtils.SquadType.FORMER_INACTIVE,
			}
			local row = SquadRow(squadPerson)
			row:id():name():role()
			row:date('joindate', 'Join Date:&nbsp;')
			row:date('inactivedate', 'Inactive Date:&nbsp;')
			row:date('leavedate', 'Leave Date:&nbsp;')

			GoldenTest('squad_row', tostring(row:create():tryMake()[1]))

			SquadUtils.storeSquadPerson(squadPerson)
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
