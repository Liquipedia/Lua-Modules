describe('Participant Table', function()
	local ParticipantTable = require('Module:ParticipantTable/Custom')

	local Array = require('Module:Array')
	local Json = require('Module:Json')
	local MockLpdb = require('Module:Mock/Lpdb')
	local Table = require('Module:Table')
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

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

	local argsRandomEvent = Table.merge(argsPlain, {is_random_event = true})

	describe('participant table is correct', function()
		it('display', function()
			MockLpdb.setUp()
			TeamTemplateMock.setUp()

			GoldenTest('participant_table', tostring(ParticipantTable(argsPlain)))
			GoldenTest('participant_table_with_seed', tostring(ParticipantTable(argsWithSeed)))
			GoldenTest('participant_table_with_seed', tostring(ParticipantTable(argsDuoOpponent)))
			GoldenTest('participant_table_with_section', tostring(ParticipantTable(argsWithSections)))
			GoldenTest('participant_table_random_event', tostring(ParticipantTable(argsRandomEvent)))

			TeamTemplateMock.tearDown()
			MockLpdb.tearDown()
		end)
	end)

	describe('parsed correctly', function()
		it('entries', function()
			MockLpdb.setUp()
			TeamTemplateMock.setUp()

			local BaseParticipantTable = require('Module:ParticipantTable/Base')
			local parse = function(args)
				local participantTable = BaseParticipantTable(args):read()
				local sections = Array.map(participantTable.sections, function(section)
					return {entries = section.entries}
				end)
				return sections
			end

			local parsedBaseEntries = {
				clem = {
					dq = false,
					isResolved = true,
					name = 'Clem',
					opponent = {
						extradata = {},
						players = {
							{
								displayName = 'Clem',
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
						players = {
							{
								displayName = 'Lambo',
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
						players = {
							{
								displayName = 'ShoWTimE',
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
						players = {
							{
								displayName = 'Bunny',
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
						players = {
							{
								displayName = 'Classic',
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
										extradata = {},
										players = {
											{
												displayName = 'Classic',
												flag = 'South Korea',
												pageIsResolved = true,
												pageName = 'Classic_(Kim_Doh_Woo)',
											},
											{
												displayName = 'ShoWTimE',
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
										extradata = {},
										players = {
											{
												displayName = 'Clem',
												flag = 'France',
												pageIsResolved = true,
												pageName = 'Clem',
											},
											{
												displayName = 'Lambo',
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

		-- can not test randomEvent parsing on faction wikis with the current setup
		-- todo after refactor to feature structure: add testcase here
	end)
--]]
end)
