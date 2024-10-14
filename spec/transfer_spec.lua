--- Triple Comment to Enable our LLS Plugin
local Json = require('Module:Json')
insulate('Transfer', function()
	allwikis('smoke', function (args, wikiName)
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
		},
		lpdbExpected = {
			{
				player = 'Supr',
				nationality = 'United States',
				fromteam = 'Team Liquid',
				toteam = 'mousesports',
				fromteamtemplate = 'team liquid 2024',
				toteamtemplate = 'mousesports',
				reference = {
					reference1 = 'https://x.com/streamerzone_gg/status/1844766204742832441',
					reference1type = 'web source',
				},
				date = '2024-10-11 00:00:00',
				wholeteam = 0,
				extradata = {
					platform = '',
					icontype = '',
					sortindex = 0,
					displaydate = '2024-10-11',
					fromteamsectemplate = '',
					displayname = 'supr',
					chars = {},
					role1sec = '',
					role2sec = '',
					toteamsectemplate = '',
					position = '',
					icon2 = '',
					toteamsec = '',
					icon = '',
					fromteamsec = '',
				},
			}
		}
	}})
end)
