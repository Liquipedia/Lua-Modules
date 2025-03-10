--- Triple Comment to Enable our LLS Plugin
local Json = require('Module:Json')
local TeamTemplateMock = require('wikis.commons.mock.mock_team_template')
insulate('Transfer', function()
	allwikis('smoke', function (args, wikiName)
		local LpdbTransferStub = stub(mw.ext.LiquipediaDB, 'lpdb_transfer')
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})

		TeamTemplateMock.setUp()

		local TransferCustom = require('Module:TransferRow/Custom')

		-- this can not check for the proper display until we have a team template fake for testing purposes
		GoldenTest('transfer_row_' .. wikiName, tostring(TransferCustom.transfer(args.input)))

		for _, row in ipairs(args.lpdbExpected) do
			local localRow = require('Module:Table').deepCopy(row)
			local obName = localRow.objectname
			localRow.objectname = nil
			assert.stub(LpdbTransferStub).was.called_with(obName, localRow)
		end

		LpdbTransferStub:revert()
		LpdbQueryStub:revert()
		TeamTemplateMock.tearDown()
	end, {
		default = {
			input = {
				name = 'supr',
				flag = 'us',
				team1 = 'team liquid',
				team2 = 'mouz',
				date = '2024-10-11',
				ref = Json.stringify{
					url = 'https://x.com/streamerzone_gg/status/1844766204742832441',
					type = 'web source',
				},
			},
			-- due to team template extension not having a fake yet
			-- some values are left as empty string instead of what would be on the wikis
			lpdbExpected = {
				{
					objectname = 'transfer_2024-10-11_000000',
					player = 'Supr',
					nationality = 'United States',
					fromteam = 'Team Liquid',
					toteam = 'MOUZ',
					fromteamtemplate = 'team liquid 2024',
					toteamtemplate = 'mouz 2021',
					reference = Json.stringify{
						reference1 = 'https://x.com/streamerzone_gg/status/1844766204742832441',
						reference1type = 'web source',
					},
					date = '2024-10-11', -- '2024-10-11 00:00:00'
					wholeteam = 0,
					extradata = Json.stringify{
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
		},
		starcraft2 = {
			input = {
				name = 'Clem',
				flag = 'fr',
				faction = 't',
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
					objectname = 'transfer_2024-10-11_000000',
					player = 'Clem',
					nationality = 'France',
					fromteam = 'Team Liquid',
					toteam = 'MOUZ',
					fromteamtemplate = 'team liquid 2024',
					toteamtemplate = 'mouz 2021',
					reference = Json.stringify{
						reference1 = 'https://x.com/streamerzone_gg/status/1844766204742832441',
						reference1type = 'web source',
					},
					date = '2024-10-11', -- '2024-10-11 00:00:00'
					wholeteam = 0,
					extradata = Json.stringify{
						platform = '',
						icontype = '',
						sortindex = 0,
						displaydate = '2024-10-11',
						fromteamsectemplate = '',
						displayname = 'Clem',
						chars = {},
						role1sec = '',
						role2sec = '',
						toteamsectemplate = '',
						position = '',
						icon2 = '',
						toteamsec = '',
						icon = '',
						fromteamsec = '',
						faction = 't',
					},
				}
			}
		},
	})
end)
