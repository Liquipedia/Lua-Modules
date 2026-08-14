--- Triple Comment to Enable our LLS Plugin
insulate('Squad', function()
	allwikis('integration tests', function(args, wikiName)
		local Info = require('Module:Info')
		if Info.config.squads.allowManual == false then
			return
		end

		local LpdbSquadStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local LpdbQueryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
		local SquadCustom = require('Module:Features/Squad/Custom')

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

--[[
Characterization tests for Squad/Utils.

These lock in today's behaviour ahead of the bulletproof-lua restructure (docs/bulletproof-lua.md),
where `Squad/Utils` is split into `Lib/Parse`, `Lib/Columns` and `Api/Store`. They describe what the
code does today, not necessarily what it ought to do.
]]
insulate('Squad/Utils', function()
	describe('status parsing', function()
		it('maps the storable statuses case insensitively', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.are_equal(SquadTypes.SquadStatus.ACTIVE, SquadUtils.statusToSquadStatus('active'))
			assert.are_equal(SquadTypes.SquadStatus.INACTIVE, SquadUtils.statusToSquadStatus('INACTIVE'))
			assert.are_equal(SquadTypes.SquadStatus.FORMER, SquadUtils.statusToSquadStatus('Former'))
		end)

		it('returns nil for nil and for unknown statuses', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			assert.is_nil(SquadUtils.statusToSquadStatus(nil))
			assert.is_nil(SquadUtils.statusToSquadStatus('retired'))
			-- FORMER_INACTIVE is derived, never parsed from input
			assert.is_nil(SquadUtils.statusToSquadStatus('former_inactive'))
		end)

		it('maps every status to a storage value, folding former inactive into former', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local toStorage = SquadTypes.SquadStatusToStorageValue
			assert.are_equal('active', toStorage[SquadTypes.SquadStatus.ACTIVE])
			assert.are_equal('inactive', toStorage[SquadTypes.SquadStatus.INACTIVE])
			assert.are_equal('former', toStorage[SquadTypes.SquadStatus.FORMER])
			assert.are_equal('former', toStorage[SquadTypes.SquadStatus.FORMER_INACTIVE])
		end)

		it('maps types both ways', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.are_equal(SquadTypes.SquadType.PLAYER, SquadTypes.TypeToSquadType.player)
			assert.are_equal(SquadTypes.SquadType.STAFF, SquadTypes.TypeToSquadType.staff)
			assert.are_equal('player', SquadTypes.SquadTypeToStorageValue[SquadTypes.SquadType.PLAYER])
			assert.are_equal('staff', SquadTypes.SquadTypeToStorageValue[SquadTypes.SquadType.STAFF])
		end)
	end)

	describe('parsePlayers', function()
		it('reads the numbered arguments and stops at the first gap', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local players = SquadUtils.parsePlayers{
				{id = 'One'},
				{id = 'Two'},
				[4] = {id = 'Four'},
				status = 'active',
			}
			assert.are_equal(2, #players)
			assert.are_equal('One', players[1].id)
			assert.are_equal('Two', players[2].id)
		end)

		it('parses json encoded rows', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local players = SquadUtils.parsePlayers{'{"id":"Baz","flag":"se"}'}
			assert.are_same({{id = 'Baz', flag = 'se'}}, players)
		end)

		it('returns an empty list when there are no rows', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			assert.are_same({}, SquadUtils.parsePlayers{status = 'active'})
		end)
	end)

	describe('anyInactive', function()
		it('is true as soon as one player has an inactive date', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			assert.is_true(SquadUtils.anyInactive{{}, {inactivedate = '2022-03-03'}})
		end)

		it('treats empty strings as no inactive date', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			assert.is_false(SquadUtils.anyInactive{{inactivedate = ''}, {}})
			assert.is_false(SquadUtils.anyInactive{})
		end)
	end)

	describe('readWrapperArgs', function()
		it('defaults to an active player squad', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			local wrapper = SquadUtils.readWrapperArgs{{id = 'Baz'}}
			assert.are_equal(SquadTypes.SquadType.PLAYER, wrapper.squadType)
			assert.are_equal(SquadTypes.SquadStatus.ACTIVE, wrapper.squadStatus)
			assert.is_nil(wrapper.title)
			assert.are_equal(1, #wrapper.players)
		end)

		it('keeps the raw args around for custom modules', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			local args = {{id = 'Baz'}, status = 'former', type = 'staff', title = 'Former Staff'}
			local wrapper = SquadUtils.readWrapperArgs(args)
			assert.are_equal(SquadTypes.SquadType.STAFF, wrapper.squadType)
			assert.are_equal(SquadTypes.SquadStatus.FORMER, wrapper.squadStatus)
			assert.are_equal('Former Staff', wrapper.title)
			assert.are_equal(args, wrapper.args)
		end)

		it('upgrades former to former inactive when any row has an inactive date', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local SquadUtils = require('Module:Features/Squad/Utils')
			local wrapper = SquadUtils.readWrapperArgs{
				status = 'former',
				{id = 'Baz'},
				{id = 'Qux', inactivedate = '2022-03-03'},
			}
			assert.are_equal(SquadTypes.SquadStatus.FORMER_INACTIVE, wrapper.squadStatus)
		end)

		it('does not upgrade active squads that have inactive dates', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local SquadUtils = require('Module:Features/Squad/Utils')
			local wrapper = SquadUtils.readWrapperArgs{
				status = 'active',
				{id = 'Qux', inactivedate = '2022-03-03'},
			}
			assert.are_equal(SquadTypes.SquadStatus.ACTIVE, wrapper.squadStatus)
		end)

		it('falls back to the defaults for unknown status and type', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			local wrapper = SquadUtils.readWrapperArgs{status = 'retired', type = 'organization'}
			assert.are_equal(SquadTypes.SquadType.PLAYER, wrapper.squadType)
			assert.are_equal(SquadTypes.SquadStatus.ACTIVE, wrapper.squadStatus)
		end)
	end)

	describe('createWrapperData', function()
		it('defaults args to an empty table', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			local wrapper = SquadUtils.createWrapperData({}, SquadTypes.SquadType.STAFF, SquadTypes.SquadStatus.FORMER)
			assert.are_same({}, wrapper.args)
			assert.is_nil(wrapper.title)
		end)
	end)

	describe('readSquadPersonArgs', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

		---Stores the person and returns what would be written to LPDB.
		---A status is always set because saving without one is an error, see below.
		---@param args table
		---@return string objectName
		---@return table fields
		local function store(args)
			local SquadUtils = require('Module:Features/Squad/Utils')
			local SquadTypes = require('Module:Features/Squad/Types')
			local objectName, fields
			local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer', function(name, row)
				objectName, fields = name, row
			end)
			local ok, err = pcall(function()
				local person = SquadUtils.readSquadPersonArgs(
					require('Module:Table').merge({status = SquadTypes.SquadStatus.ACTIVE}, args)
				)
				person:save()
			end)
			storeStub:revert()
			assert(ok, err)
			return objectName, fields
		end

		before_each(TeamTemplateMock.setUp)
		after_each(TeamTemplateMock.tearDown)

		it('requires an id or a name', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			assert.has_error(function() SquadUtils.readSquadPersonArgs{flag = 'se'} end, 'id or name is required')
			assert.has_error(function() SquadUtils.readSquadPersonArgs{id = '', name = ''} end, 'id or name is required')
		end)

		it('cannot be stored without a status', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
			local ok, err = pcall(function() SquadUtils.readSquadPersonArgs{id = 'Baz'}:save() end)
			storeStub:revert()
			assert.is_false(ok)
			assert.is_truthy(tostring(err):find('squadplayer expects status to be set', 1, true))
		end)

		it('falls back from id to name, and links to the id', function()
			local _, fields = store{name = 'Foo Bar'}
			assert.are_equal('Foo Bar', fields.id)
			assert.are_equal('Foo Bar', fields.link)
			assert.are_equal('Foo Bar', fields.name)
		end)

		it('resolves the link through redirects', function()
			local resolveStub = stub(mw.ext.TeamLiquidIntegration, 'resolve_redirect', function(name)
				return name .. ' (resolved)'
			end)
			local _, fields = store{id = 'Baz', link = 'Baz (player)'}
			resolveStub:revert()
			assert.are_equal('Baz (player) (resolved)', fields.link)
		end)

		it('expands the flag into a country name', function()
			local _, fields = store{id = 'Baz', flag = 'se'}
			assert.are_equal('Sweden', fields.nationality)
		end)

		it('upper cases the first letter of the role', function()
			local _, fields = store{id = 'Baz', role = 'sub'}
			assert.are_equal('Sub', fields.role)
		end)

		it('derives the Captain role from captain and igl, but only when no role is given', function()
			local _, captainFields = store{id = 'Baz', captain = 'true'}
			assert.are_equal('Captain', captainFields.role)

			local _, iglFields = store{id = 'Baz', igl = 'true'}
			assert.are_equal('Captain', iglFields.role)

			local _, roleFields = store{id = 'Baz', igl = 'true', role = 'sub'}
			assert.are_equal('Sub', roleFields.role)
		end)

		it('reads the own team template off the page title', function()
			local titleStub = stub(mw.title, 'getCurrentTitle', function()
				return {baseText = 'Team Liquid'}
			end)
			local _, fields = store{id = 'Baz'}
			titleStub:revert()
			assert.are_equal('team liquid 2024', fields.teamtemplate)
		end)

		it('leaves the team template empty when the page is not a team', function()
			local _, fields = store{id = 'Baz'}
			assert.are_equal('', fields.teamtemplate)
		end)

		it('resolves the new team to both a page and a template', function()
			local _, fields = store{id = 'Baz', newteam = 'mouz', newteamrole = 'Coach'}
			assert.are_equal('MOUZ', fields.newteam)
			assert.are_equal('mouz 2021', fields.newteamtemplate)
			assert.are_equal('Coach', fields.newteamrole)
		end)

		it('accepts newrole as an alias for newteamrole', function()
			local _, fields = store{id = 'Baz', newteam = 'mouz', newrole = 'Analyst'}
			assert.are_equal('Analyst', fields.newteamrole)
		end)

		it('ignores a new team that has no team template', function()
			local _, fields = store{id = 'Baz', newteam = 'retired'}
			assert.are_equal('', fields.newteam)
			assert.are_equal('', fields.newteamtemplate)
		end)

		it('cleans the dates and keeps the raw input as a display value', function()
			local _, fields = store{
				id = 'Baz',
				joindate = '2022-01-01',
				leavedate = '2022-05-01 <ref>source</ref>',
				inactivedate = '2022-03-??',
			}
			assert.are_equal('2022-01-01', fields.joindate)
			assert.are_equal('2022-05-01', fields.leavedate)
			assert.are_equal('2022-03-01', fields.inactivedate)
			assert.is_nil(fields.extradata.joindatedisplay)
			assert.are_equal('2022-05-01 <ref>source</ref>', fields.extradata.leavedatedisplay)
			assert.are_equal('2022-03-??', fields.extradata.inactivedatedisplay)
		end)

		it('records a display value for dates that are missing entirely', function()
			-- an unset date cleans to '' which differs from nil, so a nil display value is recorded
			local _, fields = store{id = 'Baz'}
			assert.are_equal('', fields.joindate)
			assert.are_equal('', fields.leavedate)
			assert.are_equal('', fields.inactivedate)
			assert.are_same({}, fields.extradata)
		end)

		it('stores loan, new team date and active team information in extradata', function()
			local _, fields = store{
				id = 'Baz',
				team = 'team liquid',
				teamrole = 'Loan',
				newteamdate = '2022-06-01 <ref>source</ref>',
				activeteam = 'mouz',
				activeteamrole = 'Main',
			}
			assert.are_equal('team liquid', fields.extradata.loanedto)
			assert.are_equal('Loan', fields.extradata.loanedtorole)
			assert.are_equal('2022-06-01', fields.extradata.newteamdate)
			assert.are_equal('mouz', fields.extradata.activeteam)
			assert.are_equal('Main', fields.extradata.activeteamrole)
		end)

		it('builds the object name from link, join date, role and status', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local objectName = store{
				id = 'Baz',
				joindate = '2022-01-01',
				role = 'sub',
				status = SquadTypes.SquadStatus.FORMER,
				type = SquadTypes.SquadType.PLAYER,
			}
			assert.are_equal('Baz_2022-01-01_Sub_former', objectName)
		end)

		it('stores former inactive as former', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local _, fields = store{id = 'Baz', status = SquadTypes.SquadStatus.FORMER_INACTIVE}
			assert.are_equal('former', fields.status)
		end)

		it('defaults the type to player when none is given', function()
			local _, fields = store{id = 'Baz', status = 0}
			assert.are_equal('player', fields.type)
		end)

		it('stores staff squads as staff', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local _, fields = store{
				id = 'Baz',
				status = SquadTypes.SquadStatus.ACTIVE,
				type = SquadTypes.SquadType.STAFF,
			}
			assert.are_equal('staff', fields.type)
		end)

		it('does not map special teams on wikis without them', function()
			local _, fields = store{id = 'Baz', newteam = 'retired'}
			assert.is_nil(fields.extradata.newteamspecial)
		end)
	end)

	describe('analyzeColumnVisibility', function()
		---@param players table[]
		---@param status SquadStatus
		---@return table<string, boolean>
		local function analyze(players, status)
			local SquadUtils = require('Module:Features/Squad/Utils')
			return SquadUtils.analyzeColumnVisibility(players, status)
		end

		---@param overrides table?
		---@return table
		local function player(overrides)
			return require('Module:Table').merge({extradata = {}}, overrides or {})
		end

		it('hides every optional column for an empty active squad', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.are_same({
				teamIcon = false,
				name = false,
				role = false,
				joindate = false,
				inactivedate = false,
				activeteam = false,
				leavedate = false,
				newteam = false,
			}, analyze({}, SquadTypes.SquadStatus.ACTIVE))
		end)

		it('shows the team icon column when someone is on loan', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local columns = analyze({player(), player{extradata = {loanedto = 'team liquid'}}},
				SquadTypes.SquadStatus.ACTIVE)
			assert.is_truthy(columns.teamIcon)
		end)

		it('shows the name and join date columns as soon as one row fills them', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local columns = analyze({player{name = 'Foo Bar', joindate = '2022-01-01'}}, SquadTypes.SquadStatus.ACTIVE)
			assert.is_true(columns.name)
			assert.is_true(columns.joindate)
		end)

		it('treats Captain and Sub as roles that do not warrant a role column', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.is_false(analyze({player{role = 'Captain'}, player{role = 'Sub'}}, SquadTypes.SquadStatus.ACTIVE).role)
			assert.is_true(analyze({player{role = 'Coach'}}, SquadTypes.SquadStatus.ACTIVE).role)
		end)

		it('falls back to the position when there is no role', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.is_true(analyze({player{position = 'Mid'}}, SquadTypes.SquadStatus.ACTIVE).role)
			-- an empty role falls through to the position, a Captain role does not
			assert.is_false(analyze({player{role = 'Captain', position = 'Mid'}}, SquadTypes.SquadStatus.ACTIVE).role)
		end)

		it('only offers the inactive columns for inactive statuses', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local rows = {player{inactivedate = '2022-03-03'}}
			assert.is_false(analyze(rows, SquadTypes.SquadStatus.ACTIVE).inactivedate)
			assert.is_false(analyze(rows, SquadTypes.SquadStatus.FORMER).inactivedate)
			assert.is_true(analyze(rows, SquadTypes.SquadStatus.INACTIVE).inactivedate)
			assert.is_true(analyze(rows, SquadTypes.SquadStatus.FORMER_INACTIVE).inactivedate)
		end)

		it('only offers the former columns for former statuses', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			local rows = {player{leavedate = '2022-05-01', newteam = 'MOUZ'}}
			assert.is_false(analyze(rows, SquadTypes.SquadStatus.ACTIVE).leavedate)
			assert.is_false(analyze(rows, SquadTypes.SquadStatus.INACTIVE).leavedate)
			assert.is_true(analyze(rows, SquadTypes.SquadStatus.FORMER).leavedate)
			assert.is_true(analyze(rows, SquadTypes.SquadStatus.FORMER_INACTIVE).leavedate)
			assert.is_true(analyze(rows, SquadTypes.SquadStatus.FORMER).newteam)
		end)

		it('shows the new team column for a role or a special team without a team', function()
			local SquadTypes = require('Module:Features/Squad/Types')
			assert.is_true(analyze({player{newteamrole = 'Coach'}}, SquadTypes.SquadStatus.FORMER).newteam)
			assert.is_true(
				analyze({player{extradata = {newteamspecial = 'Team/retired'}}}, SquadTypes.SquadStatus.FORMER).newteam
			)
		end)

		it('only shows the active team column for teams that have a template', function()
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')
			local SquadTypes = require('Module:Features/Squad/Types')
			TeamTemplateMock.setUp()
			assert.is_true(
				analyze({player{extradata = {activeteam = 'mouz'}}}, SquadTypes.SquadStatus.INACTIVE).activeteam
			)
			assert.is_false(
				analyze({player{extradata = {activeteam = 'not a team'}}}, SquadTypes.SquadStatus.INACTIVE).activeteam
			)
			TeamTemplateMock.tearDown()
		end)
	end)

	describe('convertAutoParameters', function()
		it('maps the legacy auto squad shape onto squad person args', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local converted = SquadUtils.convertAutoParameters{
				id = 'Baz',
				page = 'Baz (player)',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				thisTeam = {role = 'Sub', position = 'Mid'},
				oldTeam = {team = 'Team Liquid'},
				newTeam = {team = 'MOUZ', role = 'Coach', date = '2022-06-01'},
			}
			-- the reference is appended unconditionally, so the dates gain a trailing space
			assert.are_equal('2022-01-01 ', converted.joindate)
			assert.are_equal('2022-05-01 ', converted.leavedate)
			assert.are_equal(converted.leavedate, converted.inactivedate)
			assert.are_equal('Baz (player)', converted.link)
			assert.are_equal('Sub', converted.role)
			assert.are_equal('Mid', converted.position)
			assert.are_equal('MOUZ', converted.newteam)
			assert.are_equal('Coach', converted.newteamrole)
			assert.are_equal('2022-06-01', converted.newteamdate)
		end)

		it('prefers the display dates when they are given', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local converted = SquadUtils.convertAutoParameters{
				id = 'Baz',
				joindate = '2022-01-01',
				joindatedisplay = '2022-01-??',
				leavedate = '2022-05-01',
				leavedatedisplay = '2022-05-??',
				thisTeam = {},
				oldTeam = {},
				newTeam = {},
			}
			assert.are_equal('2022-01-?? ', converted.joindate)
			assert.are_equal('2022-05-?? ', converted.leavedate)
		end)

		it('only carries the old team over for loans', function()
			local SquadUtils = require('Module:Features/Squad/Utils')
			local loaned = SquadUtils.convertAutoParameters{
				id = 'Baz',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				thisTeam = {role = 'Loan'},
				oldTeam = {team = 'Team Liquid'},
				newTeam = {},
			}
			assert.are_equal('Team Liquid', loaned.team)

			local notLoaned = SquadUtils.convertAutoParameters{
				id = 'Baz',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				thisTeam = {role = 'Sub'},
				oldTeam = {team = 'Team Liquid'},
				newTeam = {},
			}
			assert.is_nil(notLoaned.team)
		end)
	end)
end)

--[[
Special team mapping and factions are wiki configuration, so they need a wiki that turns them on.
]]
insulate('Squad/Utils on starcraft2', function()
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

	setup(function()
		SetActiveWiki('starcraft2')
		TeamTemplateMock.setUp()
	end)

	teardown(function()
		TeamTemplateMock.tearDown()
		SetActiveWiki()
	end)

	---@param args table
	---@return table fields
	local function store(args)
		local SquadUtils = require('Module:Features/Squad/Utils')
		local SquadTypes = require('Module:Features/Squad/Types')
		local fields
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer', function(_, row)
			fields = row
		end)
		local ok, err = pcall(function()
			SquadUtils.readSquadPersonArgs(
				require('Module:Table').merge({status = SquadTypes.SquadStatus.ACTIVE}, args)
			):save()
		end)
		storeStub:revert()
		assert(ok, err)
		return fields
	end

	it('maps the known special teams', function()
		local SquadTypes = require('Module:Features/Squad/Types')
		assert.are_same({
			retired = 'Team/retired',
			inactive = 'Team/inactive',
			['passed away'] = 'Team/passed away',
			military = 'Team/military',
		}, SquadTypes.specialTeamsTemplateMapping)

		assert.are_equal('Team/retired', store{id = 'Baz', newteam = 'retired'}.extradata.newteamspecial)
		assert.are_equal('Team/military', store{id = 'Baz', newteam = 'military'}.extradata.newteamspecial)
	end)

	it('leaves unknown special teams unmapped', function()
		local fields = store{id = 'Baz', newteam = 'not a team'}
		assert.are_equal('', fields.newteam)
		assert.is_nil(fields.extradata.newteamspecial)
	end)

	it('does not map a special team when the new team resolves to a real team', function()
		assert.is_nil(store{id = 'Baz', newteam = 'mouz'}.extradata.newteamspecial)
	end)

	it('reads the faction, preferring faction over race', function()
		assert.are_equal('z', store{id = 'Baz', faction = 'zerg'}.extradata.faction)
		assert.are_equal('p', store{id = 'Baz', race = 'protoss'}.extradata.faction)
		assert.are_equal('z', store{id = 'Baz', faction = 'zerg', race = 'protoss'}.extradata.faction)
	end)
end)

--[[
Characterization tests for Squad/Controller, the orchestration that the restructure keeps but
rewires. The rendered markup is asserted in full so that moving `Widget/Squad/*` into the feature
folder has to keep producing the same output.
]]
insulate('Squad/Controller', function()
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

	before_each(function()
		TeamTemplateMock.setUp()
		stub(mw.ext.LiquipediaDB, 'lpdb', {})
	end)

	after_each(function()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		TeamTemplateMock.tearDown()
	end)

	it('stores one row per player and renders them in input order', function()
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local SquadController = require('Module:Features/Squad/Controller')

		local html = tostring(SquadController.run{
			status = 'active',
			{id = 'Baz', flag = 'se'},
			{id = 'Qux', flag = 'de'},
		})

		assert.spy(storeStub).was.called(2)
		assert.stub(storeStub).was.called_with('Baz___active', match.is_table())
		assert.stub(storeStub).was.called_with('Qux___active', match.is_table())
		assert.is_true(html:find('Baz', 1, true) < html:find('Qux', 1, true))
		storeStub:revert()
	end)

	it('renders a former squad with every column the rows ask for', function()
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local SquadController = require('Module:Features/Squad/Controller')

		local html = tostring(SquadController.run{
			status = 'former',
			{
				id = 'Baz',
				flag = 'se',
				name = 'Foo Bar',
				role = 'igl',
				joindate = '2022-01-01',
				inactivedate = '2022-03-03',
				leavedate = '2022-05-01',
				newteam = 'mouz',
			},
			{
				id = 'Qux',
				flag = 'de',
				position = 'Mid',
				joindate = '2021-02-02',
				leavedate = '2023-04-04',
				team = 'team liquid',
				teamrole = 'Loan',
			},
		})
		storeStub:revert()

		-- an inactive date on a former squad turns it into a former inactive squad, which adds the column
		assert.are_equal(
			'<tr class="table2__row--head table2__row--head-title">' ..
			'<th>ID</th><th></th><th>Name</th><th></th><th>Join Date</th>' ..
			'<th>Inactive Date</th><th>Leave Date</th><th>New Team</th></tr>',
			html:match('<tr class="table2__row%-%-head.-</tr>')
		)
		assert.is_truthy(html:find('<div class="table2__title">Former Squad</div>', 1, true))
		-- the loan is rendered as a team icon plus the loan role
		assert.is_truthy(html:find('<small><i>Loan</i></small>', 1, true))
		-- 'igl' is a role like any other here; only captain/igl without a role become Captain
		assert.is_truthy(html:find('>Igl</td>', 1, true))
	end)

	it('lets a wiki adjust every row before it is stored', function()
		local seen, stored = {}, {}
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer', function(objectName, fields)
			stored[objectName] = fields
		end)
		local SquadController = require('Module:Features/Squad/Controller')

		SquadController.run({status = 'active', {id = 'Baz'}, {id = 'Qux'}}, function(squadData, squadPlayer)
			table.insert(seen, {status = squadData.squadStatus, id = squadPlayer.id})
			squadPlayer.extradata = {adjusted = 'yes'}
		end)
		storeStub:revert()

		local SquadTypes = require('Module:Features/Squad/Types')
		assert.are_same({
			{status = SquadTypes.SquadStatus.ACTIVE, id = 'Baz'},
			{status = SquadTypes.SquadStatus.ACTIVE, id = 'Qux'},
		}, seen)
		assert.are_same({adjusted = 'yes'}, stored['Baz___active'].extradata)
		assert.are_same({adjusted = 'yes'}, stored['Qux___active'].extradata)
	end)

	it('renders an untitled empty table for an active squad without players', function()
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local SquadController = require('Module:Features/Squad/Controller')

		local html = tostring(SquadController.run{status = 'active'})
		storeStub:revert()

		assert.spy(storeStub).called(0)
		-- an active player squad has no default title, unlike inactive/former ones
		assert.is_nil(html:find('table2__title', 1, true))
		assert.is_nil(html:find('table2__row--body', 1, true))
	end)

	it('converts legacy auto rows when the wiki has not moved to the standardized auto squad', function()
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local SquadController = require('Module:Features/Squad/Controller')
		local SquadTypes = require('Module:Features/Squad/Types')

		SquadController.runAuto({
			{
				id = 'Baz',
				page = 'Baz',
				joindate = '2022-01-01',
				leavedate = '2022-05-01',
				thisTeam = {role = 'Sub'},
				oldTeam = {},
				newTeam = {team = 'mouz'},
			},
		}, SquadTypes.SquadStatus.FORMER, SquadTypes.SquadType.PLAYER, 'Former Players')

		assert.stub(storeStub).was.called_with('Baz_2022-01-01_Sub_former', match.is_table())
		storeStub:revert()
	end)

	it('titles the table with the custom title given to runAuto', function()
		local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer')
		local SquadController = require('Module:Features/Squad/Controller')
		local SquadTypes = require('Module:Features/Squad/Types')

		local html = tostring(SquadController.runAuto(
			{},
			SquadTypes.SquadStatus.FORMER,
			SquadTypes.SquadType.PLAYER,
			'Former Players'
		))
		assert.is_truthy(html:find('<div class="table2__title">Former Players</div>', 1, true))
		storeStub:revert()
	end)
end)

insulate('Squad/Controller on a wiki without manual squads', function()
	setup(function() SetActiveWiki('stormgate') end)
	teardown(function() SetActiveWiki() end)

	it('refuses to run', function()
		local SquadController = require('Module:Features/Squad/Controller')
		assert.has_error(function()
			SquadController.run{status = 'active', {id = 'Baz'}}
		end, 'This wiki does not use manual squad tables')
	end)
end)
