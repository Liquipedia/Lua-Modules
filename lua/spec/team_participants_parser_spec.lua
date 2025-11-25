--- Triple Comment to Enable our LLS Plugin
describe('Team Participants Parser', function()
	local TeamParticipantsWikiParser
	local Array
	local Table

	before_each(function()
		TeamParticipantsWikiParser = require('Module:TeamParticipants/Parse/Wiki')
		Array = require('Module:Array')
		Table = require('Module:Table')
	end)

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
				assert.is_not_nil(result.participants[1].opponent)
				assert.is_not_nil(result.participants[2].opponent)
				assert.is_not_nil(result.participants[3].opponent)
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

				assert.is_not_nil(result.participants[1].date)
			end)

			it('falls back to contextual date', function()
				local args = {
					createBasicParticipantInput(),
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.is_not_nil(result.participants[1].date)
			end)

			it('handles empty input', function()
				local args = {}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.are_equal(0, #result.participants)
			end)

			it('maps participants correctly', function()
				local args = {
					createBasicParticipantInput({[1] = 'team liquid'}),
				}

				local result = TeamParticipantsWikiParser.parseWikiInput(args)

				assert.is_table(result.participants[1])
				assert.is_table(result.participants[1].opponent)
				assert.are_equal('team', result.participants[1].opponent.type)
			end)
		end)
	end)

	describe('parseParticipant', function()
		insulate('basic team participant parsing', function()
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

			it('parses basic team opponent', function()
				local input = createBasicParticipantInput({[1] = 'team liquid'})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_table(result.opponent)
				assert.are_equal('team', result.opponent.type)
				assert.is_not_nil(result.opponent.template)
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

			it('resolves opponent with date', function()
				local input = createBasicParticipantInput({[1] = 'team liquid'})
				local date = os.time()

				local result = TeamParticipantsWikiParser.parseParticipant(input, date)

				assert.is_not_nil(result.opponent)
				assert.is_not_nil(result.date)
			end)
		end)

		insulate('TBD opponent with contenders', function()
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

			it('parses contenders into TBD opponent with potentialQualifiers', function()
				local input = {
					contenders = {'team liquid', 'bds', 'mouz'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tbd', result.opponent.template)
				assert.are_equal(3, #result.potentialQualifiers)
				assert.is_not_nil(result.potentialQualifiers[1].template)
				assert.is_not_nil(result.potentialQualifiers[2].template)
				assert.is_not_nil(result.potentialQualifiers[3].template)
			end)

			it('generates warnings for invalid contenders', function()
				local input = {
					contenders = 'not a table'
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(1, #result.warnings)
				assert.matches('Invalid contenders: expected a list of non%-empty strings', result.warnings[1])
			end)

			it('generates warning for empty string contender with position', function()
				local input = {
					contenders = {'team liquid', '', 'mouz'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(1, #result.warnings)
				assert.matches('Invalid contender entry at position 2', result.warnings[1])
				assert.are_equal(2, #result.potentialQualifiers)
			end)

			it('TBD opponent has empty players array', function()
				local input = {
					contenders = {'team liquid', 'bds'}
				}

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_table(result.opponent.players)
				assert.are_equal(0, #result.opponent.players)
			end)
		end)

		insulate('qualification structure parsing', function()
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

			it('returns nil when qualification is missing', function()
				local input = createBasicParticipantInput()

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_nil(result.qualification)
			end)

			it('collects warnings from invalid qualification', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
						placement = 'invalid',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_truthy(#result.warnings > 0)
			end)
		end)

		insulate('notes parsing', function()
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

			it('parses notes with text', function()
				local input = createBasicParticipantInput({
					notes = {
						{'Note 1'},
						{'Note 2'},
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(2, #result.notes)
				assert.are_equal('Note 1', result.notes[1].text)
				assert.are_equal('Note 2', result.notes[2].text)
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
		end)

		insulate('aliases expansion', function()
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

			it('parses input aliases separated by semicolons', function()
				local input = createBasicParticipantInput({
					aliases = 'TL;Team Liquid;Liquid',
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_truthy(#result.aliases >= 3)
			end)

			it('adds opponent name to aliases', function()
				local input = createBasicParticipantInput({[1] = 'team liquid'})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				local hasTeamName = Array.any(result.aliases, function(alias)
					return alias:lower():find('liquid')
				end)
				assert.is_true(hasTeamName)
			end)

			it('handles empty aliases', function()
				local input = createBasicParticipantInput()

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.is_truthy(#result.aliases >= 1)
			end)
		end)

		insulate('shouldImportFromDb flag', function()
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

		insulate('date override per participant', function()
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

			it('uses participant date when provided', function()
				local contextDate = os.time({year = 2024, month = 1, day = 1})
				local input = createBasicParticipantInput({
					date = '2024-06-15',
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, contextDate)

				assert.is_not_nil(result.date)
			end)

			it('falls back to context date', function()
				local contextDate = os.time({year = 2024, month = 1, day = 1})
				local input = createBasicParticipantInput()

				local result = TeamParticipantsWikiParser.parseParticipant(input, contextDate)

				assert.are_equal(contextDate, result.date)
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

			it('handles empty players array', function()
				local input = {}

				local result = TeamParticipantsWikiParser.parsePlayers(input)

				assert.are_equal(0, #result)
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

		insulate('player data structure', function()
			it('parses displayName and pageName', function()
				local playerInput = {'PlayerName', link = 'Player_Link'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal('PlayerName', result.displayName)
				assert.are_equal('Player_Link', result.pageName)
			end)

			it('parses flag', function()
				local playerInput = {'PlayerName', flag = 'us'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.is_not_nil(result.flag)
			end)

			it('has extradata structure', function()
				local playerInput = {'PlayerName'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.is_table(result.extradata)
			end)
		end)

		insulate('player extradata fields', function()
			it('parses roles via RoleUtil', function()
				local playerInput = {'PlayerName', role = 'mid'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.is_table(result.extradata.roles)
			end)

			it('parses trophies as number', function()
				local playerInput = {'PlayerName', trophies = '3'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal(3, result.extradata.trophies)
			end)

			it('defaults type to player', function()
				local playerInput = {'PlayerName'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal('player', result.extradata.type)
			end)

			it('preserves type override for staff', function()
				local playerInput = {'CoachName', type = 'staff'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal('staff', result.extradata.type)
			end)

			it('preserves type override for sub', function()
				local playerInput = {'SubName', type = 'sub'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal('sub', result.extradata.type)
			end)

			it('preserves type override for former', function()
				local playerInput = {'FormerName', type = 'former'}

				local result = TeamParticipantsWikiParser.parsePlayer(playerInput)

				assert.are_equal('former', result.extradata.type)
			end)
		end)
	end)

	describe('Qualification Parsing', function()
		insulate('qualification method variations', function()
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

			it('parses method=invite correctly', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'invite',
						text = 'Direct Invite',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('invite', result.qualification.method)
			end)

			it('parses method=qual correctly', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
					}
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
		end)

		insulate('qualification type variations', function()
			local TeamTemplateMock
			local LpdbQuery
			local TournamentGetStub

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)

				local Tournament = require('Module:Tournament')
				TournamentGetStub = stub(Tournament, 'getTournament')
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
				TournamentGetStub:revert()
			end)

			it('detects tournament type with valid page', function()
				TournamentGetStub.returns({
					pageName = 'Test/Tournament',
					displayName = 'Test Tournament',
					icon = 'Test.png',
					iconDark = 'Test_dark.png',
				})

				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						page = 'Test/Tournament',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('tournament', result.qualification.type)
				assert.is_not_nil(result.qualification.tournament)
			end)

			it('falls back to other type when tournament page is invalid', function()
				TournamentGetStub.returns(nil)

				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						page = 'Nonexistent/Tournament',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('other', result.qualification.type)
				assert.is_nil(result.qualification.tournament)
			end)

			it('detects external type with url', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						url = 'https://example.com/qualifier',
						text = 'External Qualifier',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('external', result.qualification.type)
				assert.are_equal('https://example.com/qualifier', result.qualification.url)
			end)

			it('defaults to other type', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Other Qualifier',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('other', result.qualification.type)
			end)
		end)

		insulate('external qualifier validation', function()
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

			it('requires text for external qualifiers', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						url = 'https://example.com',
					}
				})

				assert.has_error(function()
					TeamParticipantsWikiParser.parseParticipant(input, os.time())
				end, 'External qualifier must have text')
			end)

			it('accepts external qualifier with text', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						url = 'https://example.com',
						text = 'External Qualifier',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal('external', result.qualification.type)
				assert.are_equal('External Qualifier', result.qualification.text)
			end)
		end)

		insulate('placement field parsing', function()
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

			it('parses valid placement number', function()
				local input = createBasicParticipantInput({
					qualification = {
						method = 'qual',
						text = 'Qualifier',
						placement = '3',
					}
				})

				local result = TeamParticipantsWikiParser.parseParticipant(input, os.time())

				assert.are_equal(3, result.qualification.placement)
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
				assert.is_truthy(#result.warnings > 0)
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
				assert.is_truthy(#result.warnings > 0)
			end)
		end)
	end)
end)
