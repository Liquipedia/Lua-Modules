--- Triple Comment to Enable our LLS Plugin
describe('Team Participants Parser', function()
	local TeamParticipantsWikiParser
	local Table

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
		Table = require('Module:Table')
	end)

	-- Helper to create a minimal valid participant input for testing.
	-- Provides sensible defaults that can be overridden per test.
	local function createBasicParticipantInput(overrides)
		return Table.merge({
			'team liquid',
			players = {
				{'player1'},
			}
		}, overrides or {})
	end

	describe('parseWikiInput', function()
		insulate('parses array of participant inputs', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses multiple participants', function()
				local args = {
					createBasicParticipantInput({[1] = 'team liquid'}),
					createBasicParticipantInput({[1] = 'bds'}),
					createBasicParticipantInput({[1] = 'mouz'}),
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.are_equal(3, #result.participants)
				assert.are_equal('team', result.participants[1].opponent.type)
			end)

			it('extracts minimumplayers parameter', function()
				local args = {
					createBasicParticipantInput(),
					minimumplayers = '5',
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.are_equal(5, result.expectedPlayerCount)
			end)

			it('parses date from args.date', function()
				local args = {
					createBasicParticipantInput(),
					date = '2024-06-15',
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.same({year = 2024, month = 6, day = 15}, result.participants[1].date)
			end)

			it('falls back to contextual date', function()
				local Variables = require('Module:Variables')
				Variables.varDefine('tournament_enddate', '2024-12-25')

				local args = {
					createBasicParticipantInput(),
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.same({day = 25, month = 12, year = 2024}, result.participants[1].date)
			end)
		end)
	end)

	describe('parseParticipant', function()
		insulate('parseParticipant behavior', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses and assigns players', function()
				local input = {
					'team liquid',
					players = {
						{'player1', flag = 'us'},
						{'player2', flag = 'ca'},
					}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(2, #result.opponent.players)
				assert.are_equal('player1', result.opponent.players[1].displayName)
				assert.are_equal('player2', result.opponent.players[2].displayName)
			end)

			it('parses contenders into TBD opponent with potentialQualifiers', function()
				local input = {
					contenders = {'team liquid', 'bds', 'mouz'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tbd', result.opponent.template)
				assert.are_equal(3, #result.potentialQualifiers)
				assert.are_equal('team liquid', result.potentialQualifiers[1].template)
				assert.are_equal('bds', result.potentialQualifiers[2].template)
				assert.are_equal('mouz', result.potentialQualifiers[3].template)
			end)

			it('generates warnings for invalid contenders', function()
				local input = {
					contenders = 'not a table'
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(1, #result.warnings)
				assert.matches('Invalid contenders: expected a list of non%-empty strings', result.warnings[1])
			end)

			it('warns on empty string contender and keeps valid ones', function()
				local input = {
					contenders = {'team liquid', '', 'mouz'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(1, #result.warnings)
				assert.matches('Invalid contender entry at position 2', result.warnings[1])
				assert.are_equal(2, #result.potentialQualifiers)
				assert.are_equal('team liquid', result.potentialQualifiers[1].template:lower())
				assert.are_equal('mouz', result.potentialQualifiers[2].template:lower())
			end)

			it('parses valid qualification structure', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier A',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_table(result.qualification)
				assert.are_equal('qual', result.qualification.method)
				assert.are_equal('Qualifier A', result.qualification.text)
			end)

			it('preserves highlighted flag', function()
				local input = createBasicParticipantInput({
					notes = {
						{'Important Note', highlighted = true},
						{'Regular Note', highlighted = false},
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_true(result.notes[1].highlighted)
				assert.is_false(result.notes[2].highlighted)
			end)

			it('filters out notes with missing text', function()
				local input = createBasicParticipantInput({
					notes = {
						{'Valid Note'},
						{highlighted = true},
						{'Another Valid Note'},
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(2, #result.notes)
				assert.are_equal('Valid Note', result.notes[1].text)
				assert.are_equal('Another Valid Note', result.notes[2].text)
			end)

			it('sets shouldImportFromDb=true when import=true', function()
				local input = createBasicParticipantInput({
					import = true,
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_true(result.shouldImportFromDb)
			end)

			it('sets shouldImportFromDb=false by default', function()
				local input = createBasicParticipantInput()

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_false(result.shouldImportFromDb)
			end)

			it('handles string "true" for import flag', function()
				local input = createBasicParticipantInput({
					import = 'true',
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_true(result.shouldImportFromDb)
			end)
		end)
	end)

	describe('parsePlayers and parsePlayer', function()
		insulate('player array mapping', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses multiple players', function()
				local input = {
					players = {
						{'player1', flag = 'us'},
						{'player2', flag = 'ca'},
						{'player3', flag = 'gb'},
					}
				}

				local result = TeamParticipantsWikiParser.parsePlayers(input)

				assert.are_equal(3, #result)
				assert.are_equal('player1', result[1].displayName)
				assert.are_equal('player2', result[2].displayName)
				assert.are_equal('player3', result[3].displayName)
			end)
		end)

		insulate('player extradata fields', function()
			it('parses trophies as number', function()
				local result = TeamParticipantsWikiParser.parsePlayer({'PlayerName', trophies = '3'})

				assert.are_equal(3, result.extradata.trophies)
			end)

			it('ignores trophies with invalid value', function()
				local result = TeamParticipantsWikiParser.parsePlayer({'PlayerName', trophies = 'not a number'})

				assert.is_nil(result.extradata.trophies)
			end)

			it('defaults type to player and preserves type overrides', function()
				local defaultInput = {'PlayerName'}
				local staffInput = {'CoachName', type = 'staff'}
				local subInput = {'SubName', type = 'sub'}

				local defaultResult = TeamParticipantsWikiParser.parsePlayer(defaultInput)
				local staffResult = TeamParticipantsWikiParser.parsePlayer(staffInput)
				local subResult = TeamParticipantsWikiParser.parsePlayer(subInput)

				assert.are_equal('player', defaultResult.extradata.type)
				assert.are_equal('staff', staffResult.extradata.type)
				assert.are_equal('sub', subResult.extradata.type)
			end)
		end)
	end)

	describe('Qualification Parsing', function()
		insulate('qualification method and placement parsing', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('parses invite qualification method', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'invite', text = 'Direct Invite'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('invite', result.qualification.method)
			end)

			it('parses qual qualification method', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', text = 'Qualifier'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('qual', result.qualification.method)
			end)

			it('returns nil when method is missing', function()
				local input = createBasicParticipantInput({
					qualification = {
						text = 'No Method',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification)
			end)

			it('parses valid placement number', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
						placement = '3',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('3', result.qualification.placement)
			end)

			it('handles missing placement', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification.placement)
			end)

			it('validates placement is positive', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
						placement = '-1',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification.placement)
				assert.is_true(#result.warnings > 0)
			end)

			it('validates placement is a whole number', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
						placement = '2.5',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification.placement)
				assert.is_true(#result.warnings > 0)
			end)
		end)

		insulate('qualification type detection and validation', function()
			local TeamTemplateMock
			local LpdbQuery

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
			end)

			it('detects tournament type and attaches tournament data', function()
				local Tournament = require('Module:Tournament')
				local TournamentGetStub = stub(Tournament, 'getTournament')
				TournamentGetStub.returns({
					pageName = 'Test/Tournament',
					displayName = 'Test Tournament',
					icon = 'Test.png',
					iconDark = 'Test_dark.png',
				})

				local input = createBasicParticipantInput({
					qualification = {method = 'qual', page = 'Test/Tournament'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tournament', result.qualification.type)
				assert.is_table(result.qualification.tournament)
				assert.are_equal('Test/Tournament', result.qualification.tournament.pageName)
				assert.are_equal('Test Tournament', result.qualification.tournament.displayName)

				TournamentGetStub:revert()
			end)

			it('detects external type and preserves url', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', url = 'https://example.com', text = 'External'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('external', result.qualification.type)
				assert.are_equal('https://example.com', result.qualification.url)
			end)

			it('detects other type for text-only qualifications', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', text = 'Other Qualifier'}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('other', result.qualification.type)
			end)

			it('requires text for external qualifiers', function()
				local input = createBasicParticipantInput({
					qualification = {method = 'qual', url = 'https://example.com'}
				})

				assert.has_error(function()
					TeamParticipantsWikiParser.parseParticipant(input, os.time())
				end, 'External or non-tournament qualifier must have text')
			end)
		end)
	end)
end)
