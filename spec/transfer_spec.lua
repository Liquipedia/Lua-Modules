local Json = require('Module:TransferRow/Custom')

--- Triple Comment to Enable our LLS Plugin
insulate('Transfer', function()
	allwikis('storage', function (args, wikiName)
		local LpdbTransferStub = stub(mw.ext.LiquipediaDB, 'lpdb_transfer')
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local TransferCustom = require('Module:TransferRow/Custom')

		GoldenTest('transfer_row_' .. wikiName, tostring(TransferCustom.transfer(args.input)))

		for _, row in ipairs(args.lpdbExpected) do
			local localRow = require('Module:Table').deepCopy(row)
			local obName = localRow.objectname
			localRow.objectname = nil
			assert.stub(LpdbTransferStub).was.called_with(obName, localRow)
		end

		LpdbTransferStub:revert()
		LpdbQueryStub:revert()
	end, {default = {
		input = {
			name = 'supr',
			team1 = 'team liquid',
			team2 = 'mouz',
			date = '2024-10-11',
			ref = Json.stringify{
				url = 'https://x.com/streamerzone_gg/status/1844766204742832441',
				type = 'web source',
			},
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
			}
		}
	}})
end)
