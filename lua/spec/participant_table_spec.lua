describe('Participant Table', function()
	local ParticipantTable = require('Module:ParticipantTable/Custom')
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local Json = require('Module:Json')
	local Table = require('Module:Table')
	local tournamentData = require('test_assets.tournaments').dummy
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

	local LpdbPlacementStub
	local LpdbQuery

	before_each(function()
		-- Team templates are mocked for every test: TeamTemplate.getRawOrNil is
		-- memoized at module scope, so a team resolved without the mock caches a
		-- nil result that leaks into later tests that do expect the mock.
		TeamTemplateMock.setUp()
		stub(mw.ext.LiquipediaDB, 'lpdb', {})
		stub(mw.ext.LiquipediaDB, 'lpdb_player')
		LpdbPlacementStub = stub(mw.ext.LiquipediaDB, 'lpdb_placement')
		LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
		InfoboxLeague.run(tournamentData)
	end)

	after_each(function ()
		TeamTemplateMock.tearDown()
		LpdbPlacementStub:revert()
		LpdbQuery:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		mw.ext.LiquipediaDB.lpdb_tournament:revert()
	end)

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
			p1link = 'Classic (Kim Doh Woo)',
			p2 = 'ShoWTimE',
		},
	}

	local argsWithSections = {
		-- section 1 (the template just calls `{{#json:|type=section}}`)
		[1] = Json.stringify{
			[1] = 'Clem',
			[2] = 'Lambo',
			[3] = 'ShoWTimE',
			title = 'Invited',
		},
		[2] = Json.stringify{
			p1 = 'Classic',
			p1flag = 'kr',
			p1faction = 'p',
			p1link = 'Classic (Kim Doh Woo)',
			title = 'test',
			p2 = Json.stringify{
				type = 'solo',
				link = 'Bunny (Korean player)',
				flag = 'kr',
				faction = 't',
				[1] = 'Bunny',
			}
		}
	}

	local argsRandomEvent = Table.merge(argsPlain, {is_random_event = true})

	describe('participant table is correct', function()
		it('display', function()
			GoldenTest('participant_table', tostring(ParticipantTable(argsPlain)))
			GoldenTest('participant_table_with_seed', tostring(ParticipantTable(argsWithSeed)))
			GoldenTest('participant_table_with_seed', tostring(ParticipantTable(argsDuoOpponent)))
			GoldenTest('participant_table_with_section', tostring(ParticipantTable(argsWithSections)))
			GoldenTest('participant_table_random_event', tostring(ParticipantTable(argsRandomEvent)))
		end)
	end)

	describe('parsed correctly', function()
		local BaseParticipantTable = require('Module:ParticipantTable/Base')
		local parse = function(args)
			local participantTable = BaseParticipantTable(args):read()
			---@type table
			local sections = Table.copy(participantTable.sections)
			-- config on faction wikis gets adjusted, hence can not compare it in current setup
			-- hence remove it for now
			sections.config = nil
			return sections
		end

		local parsedBaseEntries = {
			clem = {
				dq = false,
				isResolved = true,
				name = 'Clem',
				opponent = {
					extradata = {
					},
					isArchon = false,
					players = {
						{
							displayName = 'Clem',
							faction = 't',
							flag = 'France',
							pageIsResolved = true,
							pageName = 'Clem',
							team = 'team liquid 2024',
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
					extradata = {
					},
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
					extradata = {
					},
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
					extradata = {
					},
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
					extradata = {
					},
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
						Table.merge({inputIndex = 1}, parsedBaseEntries.clem),
						Table.merge({inputIndex = 2}, parsedBaseEntries.lambo),
						Table.merge({inputIndex = 3}, parsedBaseEntries.showtime),
					},
				},
			},
			parse(argsPlain)
		)

		assert.are_same(
			{
				{
					entries = {
						Table.merge({inputIndex = 1, seed = 1}, parsedBaseEntries.clem),
						Table.merge({inputIndex = 2, seed = 3}, parsedBaseEntries.lambo),
						Table.merge({inputIndex = 3, seed = 2}, parsedBaseEntries.showtime),
					},
				},
			},
			parse(argsWithSeed)
		)

		assert.are_same(
			{
					{
						entries = {
							{
								dq = false,
								inputIndex = 2,
								isResolved = true,
								name = 'Classic_(Kim_Doh_Woo) / ShoWTimE',
								opponent = {
									extradata = {
									},
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
								inputIndex = 1,
								isResolved = true,
								name = 'Clem / Lambo',
								opponent = {
									extradata = {
									},
									isArchon = false,
									players = {
										{
											displayName = 'Clem',
											faction = 't',
											flag = 'France',
											pageIsResolved = true,
											pageName = 'Clem',
											team = 'team liquid 2024',
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

		assert.are_same(
			{
				{
					entries = {
						Table.merge({inputIndex = 1}, parsedBaseEntries.clem),
						Table.merge({inputIndex = 2}, parsedBaseEntries.lambo),
						Table.merge({inputIndex = 3}, parsedBaseEntries.showtime),
					},
				},
				{
					entries = {
						Table.merge({inputIndex = 2}, parsedBaseEntries.bunny),
						Table.merge({inputIndex = 1}, parsedBaseEntries.classic),
					},
				},
			},
			parse(argsWithSections)
		)

		-- can not test randomEvent parsing on faction wikis with the current setup
		-- todo after refactor to feature structure: add testcase here
	end)
end)
