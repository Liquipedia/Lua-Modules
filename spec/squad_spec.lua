--- Triple Comment to Enable our LLS Plugin
insulate('Squad', function()
	allwikis('storage', function (args, wikiName)
		local Info = require('Module:Info')
		if Info.config.squads.allowManual == false then
			return
		end
		local LpdbSquadStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local SquadCustom = require('Module:Squad/Custom')

		GoldenTest('squad_row_' .. wikiName, tostring(SquadCustom.run(args.input)))

		for _, row in ipairs(args.lpdbExpected) do
			local localRow = require('Module:Table').deepCopy(row)
			local obName = localRow.objectname
			localRow.objectname = nil
			assert.stub(LpdbSquadStub).was.called_with(obName, localRow)
		end

		LpdbSquadStub:revert()
		LpdbQueryStub:revert()
	end, {default = {
		input = {
			status = 'former',
			{
				id = 'Baz',
				flag = 'se',
				name = 'Foo Bar',
				joindate = '2022-01-01',
				inactivedate = '2022-03-03',
				leavedate = '2022-05-01',
			}
		},
		lpdbExpected = {
			{
				objectname = 'Baz_2022-01-01__former',
				id = 'Baz',
				inactivedate = '2022-03-03',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				link = 'Baz',
				name = 'Foo Bar',
				nationality = 'Sweden',
				type = 'player',
				newteam = '',
				newteamtemplate = '',
				position = '',
				role = '',
				status = 'former',
				teamtemplate = '',
				extradata = {},
			}
		}
	}})
end)
