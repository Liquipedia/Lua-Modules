describe('Participant Table', function()
	-- with sc2 we can check all relevant tests, on non faction wikis incl commons we can not, hence test on sc2
	SetActiveWiki('starcraft2')
	local ParticipantTable = require('Module:Features/ParticipantTable/Custom')

	local Array = require('Module:Array')
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local Json = require('Module:Json')
	local MockLpdb = require('Module:Mock/Lpdb')
	local Table = require('Module:Table')
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
	local tournamentData = require('test_assets.tournaments').dummy

	local argsPlain = {
		[1] = 'Clem',
		[2] = 'Lambo',
		[3] = 'ShoWTimE',
	}

	local argsWithSeed = {
		p1 = 'Clem', p1seed = 1,
		p2 = 'Lambo', p2seed = 3,
		p3 = 'ShoWTimE', p3seed = 2,
	}

	local argsDuoOpponent = {
		[1] = Json.stringify{
			type = 'duo',
			p1 = 'Clem',
			p2 = 'Lambo',
		},
		[2] = Json.stringify{
			type = 'duo',
			p1 = 'Classic',
			p1flag = 'kr',
			p1faction = 'p',
			p1link = 'Classic_(Kim_Doh_Woo)',
			p2 = 'ShoWTimE',
		},
	}

	local argsWithSections = {
		-- section 1 (the template just calls `{{#json:|type=section}}`)
		[1] = Json.stringify{
			type = 'section',
			p1 = 'Clem',
			p2 = 'Lambo',
			p3 = 'ShoWTimE',
			title = 'Invited',
		},
		-- section 2 (the template just calls `{{#json:|type=section}}`)
		[2] = Json.stringify{
			type = 'section',
			p1 = 'Classic',
			p1flag = 'kr',
			p1faction = 'p',
			p1link = 'Classic_(Kim_Doh_Woo)',
			title = 'test',
			p2 = Json.stringify{
				type = 'solo',
				link = 'Bunny_(Korean_player)',
				flag = 'kr',
				faction = 't',
				name = 'Bunny',
			}
		}
	}

	describe('participant table is correct', function()
		it('display', function()
			MockLpdb.setUp()
			TeamTemplateMock.setUp()
			stub(mw.ext.LiquipediaDB, "lpdb_tournament")
			stub(mw.ext.LiquipediaDB, "lpdb_placement")
			InfoboxLeague.run(tournamentData)

			local notAsFactionTable = function(args)
				return Table.merge(args, {soloAsFactionTable = false})
			end

			GoldenTest('participant_table', tostring(ParticipantTable.run(notAsFactionTable(argsPlain))))
			GoldenTest('participant_faction_table', tostring(ParticipantTable.run(argsPlain)))
			GoldenTest('participant_table_with_seed', tostring(ParticipantTable.run(notAsFactionTable(argsWithSeed))))
			-- doesn't work yet due to it not being implemented yet
			--GoldenTest('participant_faction_table_with_seed', tostring(ParticipantTable.run(argsWithSeed)))
			GoldenTest('participant_table_with_duo', tostring(ParticipantTable.run(argsDuoOpponent)))
			GoldenTest('participant_table_with_section', tostring(ParticipantTable.run(notAsFactionTable(argsWithSections))))
			GoldenTest('participant_faction_table_with_section', tostring(ParticipantTable.run(argsWithSections)))

			mw.ext.LiquipediaDB.lpdb_tournament:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_placement:revert()
			TeamTemplateMock.tearDown()
			MockLpdb.tearDown()
		end)
	end)

	describe('parsed correctly', function()
		local Controller = require('Module:Features/ParticipantTable/Controller')

		it('config', function()
			MockLpdb.setUp()
			TeamTemplateMock.setUp()
			local parse = function(args)
				local config = Controller._parseAndProcess(args)
				return config
			end

			assert.are_same(
				{
					storage = true,
					syncPlayers = true,
					showCountBySection = false,
					colSpan = 4,
					onlyNotable = false,
					sortPlayers = true,
					sortOpponents = true,
					showTeams = true,
					importOnlyQualified = false,
					display = true,
					showTitle = true,
					soloAsFactionTable = true,
					manualFactionCounts = {},
					factionColumnWidth = 212,
					showCountByFaction = false,
					width = (212 * 4) .. 'px',
					columnWidth = '25%',

				},
				parse(argsPlain)
			)

			assert.are_same(
				{
					storage = true,
					syncPlayers = true,
					showCountBySection = false,
					colSpan = 4,
					onlyNotable = false,
					sortPlayers = true,
					sortOpponents = true,
					showTeams = true,
					importOnlyQualified = false,
					display = true,
					showTitle = true,
					soloAsFactionTable = false,
					manualFactionCounts = {},
					factionColumnWidth = 212,
					showCountByFaction = false,
					width = (212 * 4) .. 'px',
					columnWidth = '25%',

				},
				parse(Table.merge(argsPlain, {soloAsFactionTable = false}))
			)
			TeamTemplateMock.tearDown()
			MockLpdb.tearDown()
		end)

		it('entries', function()
			MockLpdb.setUp()
			TeamTemplateMock.setUp()
			local parse = function(args)
				local _, sections = Controller._parseAndProcess(args)
				return Array.map(sections, function(section)
					return {entries = section.entries}
				end)
			end

			local parsedBaseEntries = {
				clem = {
					dq = false,
					isResolved = true,
					name = 'Clem',
					opponent = {
						extradata = {},
						isArchon = false,
						players = {
							{
								displayName = 'Clem',
								faction = 't',
								flag = 'France',
								pageIsResolved = true,
								pageName = 'Clem',
							},
						},
						type = 'solo',
					},
					sortName = 'Clem',
				},
				lambo = {
					dq = false,
					isResolved = true,
					name = 'Lambo',
					opponent = {
						extradata = {},
						isArchon = false,
						players = {
							{
								displayName = 'Lambo',
								faction = 'z',
								flag = 'Germany',
								pageIsResolved = true,
								pageName = 'Lambo',
							},
						},
						type = 'solo',
					},
					sortName = 'Lambo',
				},
				showtime = {
					dq = false,
					isResolved = true,
					name = 'ShoWTimE',
					opponent = {
						extradata = {},
						isArchon = false,
						players = {
							{
								displayName = 'ShoWTimE',
								faction = 'p',
								flag = 'Germany',
								pageIsResolved = true,
								pageName = 'ShoWTimE',
							},
						},
						type = 'solo',
					},
					sortName = 'ShoWTimE',
				},
				bunny = {
					dq = false,
					isResolved = true,
					name = 'Bunny_(Korean_player)',
					opponent = {
						extradata = {},
						isArchon = false,
						players = {
							{
								displayName = 'Bunny',
								faction = 't',
								flag = 'South Korea',
								pageIsResolved = true,
								pageName = 'Bunny_(Korean_player)',
							},
						},
						type = 'solo',
					},
					sortName = 'Bunny_(Korean_player)',
				},
				classic = {
					dq = false,
					isResolved = true,
					name = 'Classic_(Kim_Doh_Woo)',
					opponent = {
						extradata = {},
						isArchon = false,
						players = {
							{
								displayName = 'Classic',
								faction = 'p',
								flag = 'South Korea',
								pageIsResolved = true,
								pageName = 'Classic_(Kim_Doh_Woo)',
							},
						},
						type = 'solo',
					},
					sortName = 'Classic_(Kim_Doh_Woo)',
				},
			}

			assert.are_same(
				{
					{
						entries = {
							parsedBaseEntries.clem,
							parsedBaseEntries.lambo,
							parsedBaseEntries.showtime,
						},
					},
				},
				parse(argsPlain)
			)
			assert.are_same(
				{
					{
						entries = {
							Table.merge({seed = 1}, parsedBaseEntries.clem),
							Table.merge({seed = 3}, parsedBaseEntries.lambo),
							Table.merge({seed = 2}, parsedBaseEntries.showtime),
						},
					},
				},
				parse(argsWithSeed)
			)
			assert.are_same(
				{
					{
						entries = {
							parsedBaseEntries.clem,
							parsedBaseEntries.lambo,
							parsedBaseEntries.showtime,
						},
					},
					{
						entries = {
							parsedBaseEntries.bunny,
							parsedBaseEntries.classic,
						},
					},
				},
				parse(argsWithSections)
			)
			assert.are_same(
				{
						{
							entries = {
								{
									dq = false,
									isResolved = true,
									name = 'Classic_(Kim_Doh_Woo) / ShoWTimE',
									opponent = {
										extradata = {},
										isArchon = false,
										players = {
											{
												displayName = 'Classic',
												faction = 'p',
												flag = 'South Korea',
												pageIsResolved = true,
												pageName = 'Classic_(Kim_Doh_Woo)',
											},
											{
												displayName = 'ShoWTimE',
												faction = 'p',
												flag = 'Germany',
												pageIsResolved = true,
												pageName = 'ShoWTimE',
											},
										},
										type = 'duo',
									},
									sortName = 'Classic_(Kim_Doh_Woo) / ShoWTimE',
								},
								{
									dq = false,
									isResolved = true,
									name = 'Clem / Lambo',
									opponent = {
										extradata = {},
										isArchon = false,
										players = {
											{
												displayName = 'Clem',
												faction = 't',
												flag = 'France',
												pageIsResolved = true,
												pageName = 'Clem',
											},
											{
												displayName = 'Lambo',
												faction = 'z',
												flag = 'Germany',
												pageIsResolved = true,
												pageName = 'Lambo',
											},
										},
										type = 'duo',
									},
									sortName = 'Clem / Lambo',
								},
							},
						},
					},
				parse(argsDuoOpponent)
			)
			TeamTemplateMock.tearDown()
			MockLpdb.tearDown()
		end)
	end)
	SetActiveWiki()
end)
