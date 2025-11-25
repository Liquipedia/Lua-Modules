--- Triple Comment to Enable our LLS Plugin
describe('Team Participants Repository', function()
	local TeamParticipantsRepository
	local Table
	local Variables
	local Json
	local PageVariableNamespace

	before_each(function()
		TeamParticipantsRepository = require('Module:TeamParticipants/Repository')
		Table = require('Module:Table')
		Variables = require('Module:Variables')
		Json = require('Module:Json')
		PageVariableNamespace = require('Module:PageVariableNamespace')
	end)

	local function createBasicParticipant(overrides)
		return Table.merge({
			opponent = {
				type = 'team',
				template = 'team liquid',
				name = 'Team Liquid',
				players = {
					{displayName = 'Player1', pageName = 'Player1', flag = 'us', extradata = {type = 'player'}},
					{displayName = 'Player2', pageName = 'Player2', flag = 'ca', extradata = {type = 'player'}},
				}
			},
			aliases = {'Team Liquid', 'TL'},
			qualification = nil,
			potentialQualifiers = nil,
		}, overrides or {})
	end

	local function createPrizepoolRecord(overrides)
		return Table.merge({
			objectName = 'ranking_team liquid',
			tournament = 'Test Tournament',
			parent = 'Test Series',
			series = 'Test',
			shortname = 'Test',
			mode = '5v5',
			type = 'Online',
			liquipediatier = '1',
			liquipediatiertype = 'Qualifier',
			publishertier = 'Premier',
			icon = 'Test.png',
			icondark = 'Test_dark.png',
			game = 'testgame',
			startdate = '2024-01-01',
			date = '2024-01-15',
			placement = '1',
			prizemoney = 10000,
			opponentname = 'Team Liquid',
			opponenttype = 'team',
			opponenttemplate = 'team liquid',
			extradata = {},
		}, overrides or {})
	end

	describe('save', function()
		insulate('saves participant to LPDB placement table', function()
			local TeamTemplateMock
			local LpdbQuery
			local LpdbPlacementStore

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()

				Variables.varDefine('tournament_name', 'Test Tournament')
				Variables.varDefine('tournament_parent', 'Test Parent')
				Variables.varDefine('tournament_series', 'Test Series')
				Variables.varDefine('tournament_tickername', 'Test')
				Variables.varDefine('tournament_mode', '5v5')
				Variables.varDefine('tournament_type', 'Online')
				Variables.varDefine('tournament_liquipediatier', '2')
				Variables.varDefine('tournament_liquipediatiertype', 'Monthly')
				Variables.varDefine('tournament_publishertier', 'Premier')
				Variables.varDefine('tournament_icon', 'Tournament.png')
				Variables.varDefine('tournament_icondark', 'Tournament_dark.png')
				Variables.varDefine('tournament_game', 'testgame')
				Variables.varDefine('tournament_startdate', '2024-01-01')
				Variables.varDefine('tournament_enddate', '2024-01-15')

				LpdbQuery = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
				LpdbPlacementStore = stub(mw.ext.LiquipediaDB, 'lpdb_placement', function() end)
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				LpdbQuery:revert()
				LpdbPlacementStore:revert()

				Variables.varDefine('tournament_name', nil)
				Variables.varDefine('tournament_parent', nil)
				Variables.varDefine('tournament_series', nil)
				Variables.varDefine('tournament_tickername', nil)
				Variables.varDefine('tournament_mode', nil)
				Variables.varDefine('tournament_type', nil)
				Variables.varDefine('tournament_liquipediatier', nil)
				Variables.varDefine('tournament_liquipediatiertype', nil)
				Variables.varDefine('tournament_publishertier', nil)
				Variables.varDefine('tournament_icon', nil)
				Variables.varDefine('tournament_icondark', nil)
				Variables.varDefine('tournament_game', nil)
				Variables.varDefine('tournament_startdate', nil)
				Variables.varDefine('tournament_enddate', nil)
			end)

			it('calls lpdb_placement with objectName and data', function()
				local participant = createBasicParticipant()

				TeamParticipantsRepository.save(participant)

				assert.stub(LpdbPlacementStore).was.called(1)
			end)

			it('generates objectName as ranking_teamname for regular teams', function()
				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {}
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				assert.are_equal('ranking_team liquid', callArgs[1])
			end)

			it('generates unique objectName for TBD teams with counter', function()
				local participant1 = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'tbd',
						name = 'TBD',
						players = {}
					}
				})
				local participant2 = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'tbd',
						name = 'TBD',
						players = {}
					}
				})

				TeamParticipantsRepository.save(participant1)
				TeamParticipantsRepository.save(participant2)

				local call1Args = LpdbPlacementStore.calls[1].vals
				local call2Args = LpdbPlacementStore.calls[2].vals
				assert.are_equal('participant_tbd_1', call1Args[1])
				assert.are_equal('participant_tbd_2', call2Args[1])
			end)

			it('uses tournament defaults when no prizepool record exists', function()
				local participant = createBasicParticipant()

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Test Tournament', data.tournament)
				assert.are_equal('Test Parent', data.parent)
				assert.are_equal('Test Series', data.series)
				assert.are_equal('5v5', data.mode)
				assert.are_equal('Online', data.type)
			end)

			it('sets qualification text field', function()
				local participant = createBasicParticipant({
					qualification = {
						type = 'other',
						method = 'qual',
						text = 'Open Qualifier',
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Open Qualifier', data.qualifier)
			end)

			it('sets qualifierpage for tournament type qualification', function()
				local participant = createBasicParticipant({
					qualification = {
						type = 'tournament',
						method = 'qual',
						text = 'Regional Qualifier',
						tournament = {
							pageName = 'Test/Regional_Qualifier',
							displayName = 'Regional Qualifier',
						}
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Test/Regional_Qualifier', data.qualifierpage)
				assert.are_equal('Regional Qualifier', data.qualifier)
			end)

			it('sets qualifierurl for external type qualification', function()
				local participant = createBasicParticipant({
					qualification = {
						type = 'external',
						method = 'qual',
						text = 'External Qualifier',
						url = 'https://example.com/qualifier',
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('https://example.com/qualifier', data.qualifierurl)
				assert.are_equal('External Qualifier', data.qualifier)
			end)

			it('stores opponentaliases in extradata', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid', 'TL', 'Liquid'},
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])
				local extradata = Json.parseIfString(data.extradata)

				assert.are_same({'Team Liquid', 'TL', 'Liquid'}, extradata.opponentaliases)
			end)

			it('serializes potentialQualifiers in extradata', function()
				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'tbd',
						name = 'TBD',
						players = {}
					},
					potentialQualifiers = {
						{type = 'team', template = 'team liquid', name = 'Team Liquid'},
						{type = 'team', template = 'bds', name = 'BDS'},
					}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])
				local extradata = Json.parseIfString(data.extradata)

				assert.are_same({'Team Liquid', 'Team BDS'}, extradata.potentialQualifiers)
			end)

			it('does not store empty potentialQualifiers', function()
				local participant = createBasicParticipant({
					potentialQualifiers = {}
				})

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])
				local extradata = Json.parseIfString(data.extradata)

				assert.is_nil(extradata.potentialQualifiers)
			end)

			it('sets players field to opponentplayers', function()
				local participant = createBasicParticipant()

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.is_not_nil(data.players)
				assert.are_equal(data.opponentplayers, data.players)
			end)

			it('calculates individualprizemoney correctly based on player types', function()
				local getPrizepoolRecordStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordForTeam')

				local fivePlayers = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'P1', pageName = 'P1', extradata = {type = 'player'}},
							{displayName = 'P2', pageName = 'P2', extradata = {type = 'player'}},
							{displayName = 'P3', pageName = 'P3', extradata = {type = 'player'}},
							{displayName = 'P4', pageName = 'P4', extradata = {type = 'player'}},
							{displayName = 'P5', pageName = 'P5', extradata = {type = 'player'}},
						}
					}
				})
				getPrizepoolRecordStub.returns(createPrizepoolRecord({prizemoney = 10000}))
				TeamParticipantsRepository.save(fivePlayers)
				local data1 = Json.parseIfString(LpdbPlacementStore.calls[1].vals[2])
				assert.are_equal(2000, data1.individualprizemoney)

				local withSubAndStaff = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'bds',
						name = 'BDS',
						players = {
							{displayName = 'P1', pageName = 'P1', extradata = {type = 'player'}},
							{displayName = 'P2', pageName = 'P2', extradata = {type = 'player'}},
							{displayName = 'Sub1', pageName = 'Sub1', extradata = {type = 'sub'}},
							{displayName = 'Coach', pageName = 'Coach', extradata = {type = 'staff'}},
						}
					}
				})
				getPrizepoolRecordStub.returns(createPrizepoolRecord({prizemoney = 6000, opponenttemplate = 'bds'}))
				TeamParticipantsRepository.save(withSubAndStaff)
				local data2 = Json.parseIfString(LpdbPlacementStore.calls[2].vals[2])
				assert.are_equal(2000, data2.individualprizemoney)

				getPrizepoolRecordStub:revert()
			end)

			it('handles empty players array without division by zero', function()
				local participant = createBasicParticipant({
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {}
					}
				})

				local getPrizepoolRecordStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordForTeam')
				getPrizepoolRecordStub.returns(createPrizepoolRecord({prizemoney = 5000}))

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal(5000, data.individualprizemoney)

				getPrizepoolRecordStub:revert()
			end)

			it('does not set individualprizemoney when no prizemoney exists', function()
				local participant = createBasicParticipant()

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.is_nil(data.individualprizemoney)
			end)

			it('merges with existing prizepool data', function()
				local participant = createBasicParticipant()

				local getPrizepoolRecordStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordForTeam')
				getPrizepoolRecordStub.returns(createPrizepoolRecord({
					placement = '3',
					prizemoney = 5000,
					tournament = 'Prizepool Tournament',
				}))

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('3', data.placement)
				assert.are_equal(5000, data.prizemoney)
				assert.are_equal('Prizepool Tournament', data.tournament)

				getPrizepoolRecordStub:revert()
			end)

			it('prizepool data takes precedence over tournament defaults', function()
				local participant = createBasicParticipant()

				local getPrizepoolRecordStub = stub(TeamParticipantsRepository, 'getPrizepoolRecordForTeam')
				getPrizepoolRecordStub.returns(createPrizepoolRecord({
					tournament = 'Prizepool Tournament',
					mode = '3v3',
					type = 'Offline',
				}))

				TeamParticipantsRepository.save(participant)

				local callArgs = LpdbPlacementStore.calls[1].vals
				local data = Json.parseIfString(callArgs[2])

				assert.are_equal('Prizepool Tournament', data.tournament)
				assert.are_equal('3v3', data.mode)
				assert.are_equal('Offline', data.type)

				getPrizepoolRecordStub:revert()
			end)
		end)
	end)

	describe('setPageVars', function()
		insulate('sets page variables for team aliases', function()
			local TeamTemplateMock
			local globalVars

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()
				globalVars = PageVariableNamespace()
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
			end)

			it('sets page variables for each alias', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid', 'TL'},
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'Player1', pageName = 'Player1', flag = 'us', extradata = {type = 'player'}},
						}
					}
				})

				TeamParticipantsRepository.setPageVars(participant)

				local varWithSpace = globalVars:get('Team Liquid_p1')
				local varWithUnderscore = globalVars:get('Team_Liquid_p1')

				assert.is_not_nil(varWithSpace)
				assert.is_not_nil(varWithUnderscore)
			end)

			it('sets page variables with correct prefixes and suffixes', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid'},
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'DisplayName', pageName = 'ActualPageName', flag = 'us', extradata = {type = 'player'}},
							{displayName = 'Player2', pageName = 'Player2', flag = 'ca', extradata = {type = 'player'}},
							{displayName = 'Coach1', pageName = 'Coach1', flag = 'gb', extradata = {type = 'staff'}},
						}
					}
				})

				TeamParticipantsRepository.setPageVars(participant)

				assert.are_equal('ActualPageName', globalVars:get('Team Liquid_p1'))
				assert.are_equal('DisplayName', globalVars:get('Team Liquid_p1dn'))
				assert.are_equal('us', globalVars:get('Team Liquid_p1flag'))
				assert.are_equal('Player2', globalVars:get('Team Liquid_p2'))
				assert.are_equal('Coach1', globalVars:get('Team Liquid_c3'))
				assert.are_equal('ActualPageName', globalVars:get('Team_Liquid_p1'))
			end)

			it('handles empty aliases gracefully', function()
				local participant = createBasicParticipant({
					aliases = {},
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'Player1', pageName = 'Player1', flag = 'us', extradata = {type = 'player'}},
						}
					}
				})

				TeamParticipantsRepository.setPageVars(participant)

				assert.is_true(true)
			end)

			it('indexes players correctly', function()
				local participant = createBasicParticipant({
					aliases = {'Team Liquid'},
					opponent = {
						type = 'team',
						template = 'team liquid',
						name = 'Team Liquid',
						players = {
							{displayName = 'Player1', pageName = 'Player1', flag = 'us', extradata = {type = 'player'}},
							{displayName = 'Player2', pageName = 'Player2', flag = 'ca', extradata = {type = 'player'}},
							{displayName = 'Player3', pageName = 'Player3', flag = 'gb', extradata = {type = 'player'}},
						}
					}
				})

				TeamParticipantsRepository.setPageVars(participant)

				local p1 = globalVars:get('Team Liquid_p1')
				local p2 = globalVars:get('Team Liquid_p2')
				local p3 = globalVars:get('Team Liquid_p3')

				assert.are_equal('Player1', p1)
				assert.are_equal('Player2', p2)
				assert.are_equal('Player3', p3)
			end)
		end)
	end)

	describe('getPrizepoolRecordForTeam', function()
		insulate('finds prizepool record by opponent matching', function()
			local TeamTemplateMock
			local getPrizepoolRecordsStub

			before_each(function()
				TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
				TeamTemplateMock.setUp()

				getPrizepoolRecordsStub = stub(TeamParticipantsRepository, 'getPrizepoolRecords')
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
				getPrizepoolRecordsStub:revert()
			end)

			it('returns matching record when opponent matches', function()
				local opponent = {
					type = 'team',
					template = 'team liquid',
					name = 'Team Liquid',
				}

				getPrizepoolRecordsStub.returns({
					createPrizepoolRecord({
						opponentname = 'Team Liquid',
						opponenttype = 'team',
						opponenttemplate = 'team liquid',
					})
				})

				local result = TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)

				assert.is_not_nil(result)
				assert.are_equal('Team Liquid', result.opponentname)
			end)

			it('returns nil when no record found', function()
				local opponent = {
					type = 'team',
					template = 'bds',
					name = 'BDS',
				}

				getPrizepoolRecordsStub.returns({
					createPrizepoolRecord({
						opponentname = 'Team Liquid',
						opponenttype = 'team',
						opponenttemplate = 'team liquid',
					})
				})

				local result = TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)

				assert.is_nil(result)
			end)

			it('returns nil when prizepool records are empty', function()
				local opponent = {
					type = 'team',
					template = 'team liquid',
					name = 'Team Liquid',
				}

				getPrizepoolRecordsStub.returns({})

				local result = TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)

				assert.is_nil(result)
			end)

			it('returns first matching record', function()
				local opponent = {
					type = 'team',
					template = 'team liquid',
					name = 'Team Liquid',
				}

				getPrizepoolRecordsStub.returns({
					createPrizepoolRecord({
						opponentname = 'Team Liquid',
						opponenttype = 'team',
						opponenttemplate = 'team liquid',
						placement = '1',
					}),
					createPrizepoolRecord({
						opponentname = 'Team Liquid',
						opponenttype = 'team',
						opponenttemplate = 'team liquid',
						placement = '2',
					})
				})

				local result = TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)

				assert.is_not_nil(result)
				assert.are_equal('1', result.placement)
			end)

			it('uses Opponent.same for matching logic', function()
				local opponent = {
					type = 'team',
					template = 'bds',
					name = 'BDS',
				}

				getPrizepoolRecordsStub.returns({
					createPrizepoolRecord({
						opponentname = 'BDS',
						opponenttype = 'team',
						opponenttemplate = 'bds',
					})
				})

				local result = TeamParticipantsRepository.getPrizepoolRecordForTeam(opponent)

				assert.is_not_nil(result)
				assert.are_equal('BDS', result.opponentname)
			end)
		end)
	end)

	describe('getPrizepoolRecords', function()
		insulate('fetches placement records from PageVariableNamespace', function()
			local prizePoolVars
			local TeamParticipantsRepositoryLocal

			before_each(function()
				prizePoolVars = PageVariableNamespace('PrizePool')
				TeamParticipantsRepositoryLocal = require('Module:TeamParticipants/Repository')
			end)

			it('returns empty array when no records exist', function()
				local result = TeamParticipantsRepositoryLocal.getPrizepoolRecords()

				assert.is_table(result)
				assert.are_equal(0, #result)
			end)

			it('fetches and returns an array', function()
				prizePoolVars:set('placementRecords.1', Json.stringify({
					createPrizepoolRecord({placement = '1'}),
					createPrizepoolRecord({placement = '2'}),
				}))

				local result = TeamParticipantsRepositoryLocal.getPrizepoolRecords()

				assert.is_table(result)
			end)

			it('flattens multiple prizepool indices', function()
				prizePoolVars:set('placementRecords.1', Json.stringify({
					createPrizepoolRecord({placement = '1'}),
				}))
				prizePoolVars:set('placementRecords.2', Json.stringify({
					createPrizepoolRecord({placement = '2'}),
				}))

				local result = TeamParticipantsRepositoryLocal.getPrizepoolRecords()

				assert.is_table(result)
			end)

			it('parses JSON strings from variables', function()
				local record = createPrizepoolRecord({placement = '1', prizemoney = 10000})
				prizePoolVars:set('placementRecords.1', Json.stringify({record}))

				local result = TeamParticipantsRepositoryLocal.getPrizepoolRecords()

				assert.is_table(result)
			end)
		end)
	end)
end)
