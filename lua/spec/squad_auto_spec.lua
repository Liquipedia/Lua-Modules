--- Triple Comment to Enable our LLS Plugin
--[[
Characterization tests for the transfer history logic in Squad/Auto.

`Squad/Auto` turns a team's transfer records into squad stints: it groups transfers per person,
walks them as a small state machine (join -> [inactive] -> leave), and maps each stint onto a squad
row. That logic is what the bulletproof-lua restructure (docs/bulletproof-lua.md) pulls out into
`Lib/History` + `Api/TransferHistory`, so these tests drive it through the public entry point and
assert on the rows it stores. They describe today's behaviour, quirks included.

The standardized auto squad is only enabled on some wikis, so these run against ageofempires.
]]

local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

--- The team the squad table is built for, and the templates used in the transfer fixtures.
local TEAM = 'MOUZ'
local TEAM_TEMPLATE = 'mouz 2021'
local OTHER_TEAM_TEMPLATE = 'team liquid 2024'

---Builds a transfer record. `extradata` is merged rather than replaced, so a test only has to name
---the extradata fields it cares about.
---@param props table?
---@return table
local function transfer(props)
	local Table = require('Module:Table')
	props = Table.copy(props or {})
	local extradata = Table.extract(props, 'extradata') or {}
	local record = Table.merge({
		player = 'Alice',
		nationality = 'se',
		date = '2022-01-01',
		fromteamtemplate = '',
		toteamtemplate = '',
		role1 = '',
		role2 = '',
		wholeteam = 0,
		reference = {},
	}, props)
	record.extradata = Table.merge({displayname = record.player}, extradata)
	return record
end

---@param date string
---@param props table?
---@return table
local function join(date, props)
	return transfer(require('Module:Table').merge({toteamtemplate = TEAM_TEMPLATE}, props or {}, {date = date}))
end

---@param date string
---@param props table?
---@return table
local function leave(date, props)
	return transfer(require('Module:Table').merge({fromteamtemplate = TEAM_TEMPLATE}, props or {}, {date = date}))
end

---@param date string
---@param props table?
---@return table
local function change(date, props)
	return transfer(require('Module:Table').merge(
		{fromteamtemplate = TEAM_TEMPLATE, toteamtemplate = TEAM_TEMPLATE},
		props or {},
		{date = date}
	))
end

---@class SquadAutoTestResult
---@field html string
---@field rows table<string, table> stored squad rows, keyed by object name
---@field objectNames string[] stored object names, in storage order
---@field queries table[] every lpdb query that was made
---@field categories string[]

---Runs the auto squad table and collects everything it stored, queried and rendered.
---@param args table arguments for Module:Squad/Auto
---@param fixtures {transfers: table[]?, person: table?, nextTeam: table?}?
---@return SquadAutoTestResult
local function runAuto(args, fixtures)
	fixtures = fixtures or {}
	local result = {rows = {}, objectNames = {}, queries = {}, categories = {}}

	local storeStub = stub(mw.ext.LiquipediaDB, 'lpdb_squadplayer', function(objectName, fields)
		table.insert(result.objectNames, objectName)
		result.rows[objectName] = fields
	end)
	local queryStub = stub(mw.ext.LiquipediaDB, 'lpdb', function(tableName, params)
		table.insert(result.queries, require('Module:Table').merge({tableName = tableName}, params))
		if tableName == 'transfer' and params.query == nil then
			-- the mass query for the team's transfers; a second page must come back empty
			return (params.offset or 0) == 0 and (fixtures.transfers or {}) or {}
		end
		if tableName == 'transfer' then
			-- the follow up query for the team a person joined next
			return fixtures.nextTeam and {fixtures.nextTeam} or {}
		end
		if tableName == 'player' and params.query == 'pagename, nationality, id, name, extradata' then
			return fixtures.person and {fixtures.person} or {}
		end
		return {}
	end)
	local categoryStub = stub(mw.ext.TeamLiquidIntegration, 'add_category', function(name)
		table.insert(result.categories, name)
	end)

	local ok, htmlOrError = pcall(function()
		-- an empty squad table returns no value at all, so it cannot be passed straight to tostring
		local display = require('Module:Squad/Auto').run(require('Module:Table').merge({team = TEAM}, args))
		return tostring(display)
	end)

	storeStub:revert()
	queryStub:revert()
	categoryStub:revert()
	assert(ok, htmlOrError)

	result.html = htmlOrError
	return result
end

insulate('Squad/Auto transfer history', function()
	setup(function()
		SetActiveWiki('ageofempires')
		TeamTemplateMock.setUp()
	end)

	teardown(function()
		TeamTemplateMock.tearDown()
		SetActiveWiki()
	end)

	describe('querying', function()
		it('queries transfers for every template of the team, on either side of the transfer', function()
			local result = runAuto{status = 'active', type = 'player'}
			local query = result.queries[1]
			assert.are_equal('transfer', query.tableName)
			assert.are_equal('date asc, objectname desc', query.order)
			assert.are_equal(5000, query.limit)

			-- every historical template is covered, and the current one is appended a second time.
			-- the order the historical templates come out in is not stable, so compare them sorted.
			local Array = require('Module:Array')
			local templates = Array.sortBy(
				Array.map(
					Array.parseCommaSeparatedString(query.conditions, ' OR '),
					function(condition) return (condition:match('::(.-)%]%]')) end
				),
				function(template) return template end
			)
			assert.are_same({
				'mousesports 2016', 'mousesports 2016', 'mousesports 2016', 'mousesports 2016',
				'mousesports orig', 'mousesports orig', 'mousesports orig', 'mousesports orig',
				'mouz 2021', 'mouz 2021', 'mouz 2021', 'mouz 2021',
				'mouz 2021', 'mouz 2021', 'mouz 2021', 'mouz 2021',
			}, templates)
			assert.is_truthy(query.conditions:find('[[fromteamtemplate::mouz 2021]]', 1, true))
			assert.is_truthy(query.conditions:find('[[extradata_fromteamsectemplate::mouz 2021]]', 1, true))
			assert.is_truthy(query.conditions:find('[[toteamtemplate::mouz 2021]]', 1, true))
			assert.is_truthy(query.conditions:find('[[extradata_toteamsectemplate::mouz 2021]]', 1, true))
		end)

		it('errors when the team has no team template', function()
			assert.has_error(function()
				runAuto{team = 'not a team', status = 'active', type = 'player'}
			end)
		end)

		it('caches the parsed history in a page variable and reuses it', function()
			local first = runAuto({status = 'active', type = 'player'}, {transfers = {join('2022-01-01')}})
			assert.are_equal(1, #first.objectNames)

			-- the cache is keyed by team name and survives within the page, so no transfer query is made
			local second = runAuto({status = 'active', type = 'player'}, {transfers = {join('2022-01-01')}})
			local transferQueries = require('Module:Array').filter(second.queries, function(query)
				return query.tableName == 'transfer' and query.query == nil
			end)
			assert.are_equal(0, #transferQueries)
			assert.are_equal(1, #second.objectNames)
		end)
	end)

	describe('active squads', function()
		it('keeps a person whose last transfer joined the team', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01', {role2 = 'Standin'}),
			}})

			assert.are_same({'Alice_2022-01-01_Standin_active'}, result.objectNames)
			local row = result.rows['Alice_2022-01-01_Standin_active']
			assert.are_equal('Alice', row.id)
			assert.are_equal('Alice', row.link)
			assert.are_equal('Sweden', row.nationality)
			assert.are_equal('Standin', row.role)
			assert.are_equal('2022-01-01', row.joindate)
			assert.are_equal('', row.leavedate)
			assert.are_equal('active', row.status)
			assert.are_equal('player', row.type)
		end)

		it('drops a person whose last transfer left the team', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01'),
				leave('2022-06-01', {toteamtemplate = OTHER_TEAM_TEMPLATE}),
			}})
			assert.are_same({}, result.objectNames)
			assert.are_equal('nil', result.html)
		end)

		it('drops a person whose last transfer made them inactive', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01'),
				change('2022-06-01', {role2 = 'Inactive'}),
			}})
			assert.are_same({}, result.objectNames)
		end)

		it('uses the most recent role change', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01'),
				change('2022-06-01', {role2 = 'Standin'}),
			}})
			assert.are_same({'Alice_2022-06-01_Standin_active'}, result.objectNames)
			assert.are_equal('2022-06-01', result.rows['Alice_2022-06-01_Standin_active'].joindate)
		end)
	end)

	describe('inactive squads', function()
		it('pairs the transfer that made someone inactive with the one before it', function()
			local result = runAuto({status = 'inactive', type = 'player'}, {transfers = {
				join('2022-01-01', {role2 = 'Standin'}),
				change('2022-06-01', {role1 = 'Standin', role2 = 'Inactive'}),
			}})

			assert.are_same({'Alice_2022-01-01_Standin_inactive'}, result.objectNames)
			local row = result.rows['Alice_2022-01-01_Standin_inactive']
			assert.are_equal('2022-01-01', row.joindate)
			assert.are_equal('2022-06-01', row.inactivedate)
			assert.are_equal('', row.leavedate)
			assert.are_equal('inactive', row.status)
		end)

		it('ignores someone who is still active', function()
			local result = runAuto({status = 'inactive', type = 'player'}, {transfers = {join('2022-01-01')}})
			assert.are_same({}, result.objectNames)
		end)

		it('ignores an inactive transfer that has nothing before it', function()
			local result = runAuto({status = 'inactive', type = 'player'}, {transfers = {
				change('2022-06-01', {role2 = 'Inactive'}),
			}})
			assert.are_same({}, result.objectNames)
		end)
	end)

	describe('former squads', function()
		it('turns a join and a leave into one stint', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2022-01-01', {role2 = 'Standin'}),
				leave('2022-06-01', {role1 = 'Standin', toteamtemplate = OTHER_TEAM_TEMPLATE, role2 = 'Coach'}),
			}})

			assert.are_same({'Alice_2022-01-01_Standin_former'}, result.objectNames)
			local row = result.rows['Alice_2022-01-01_Standin_former']
			assert.are_equal('2022-01-01', row.joindate)
			assert.are_equal('2022-06-01', row.leavedate)
			assert.are_equal('Team Liquid', row.newteam)
			assert.are_equal(OTHER_TEAM_TEMPLATE, row.newteamtemplate)
			assert.are_equal('Coach', row.newteamrole)
			assert.are_equal('2022-06-01', row.extradata.newteamdate)
			assert.are_equal('former', row.status)
		end)

		it('splits a role change into two stints', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2021-01-01', {role2 = 'Standin'}),
				change('2022-01-01', {role1 = 'Standin', role2 = 'Captain'}),
				leave('2022-06-01', {role1 = 'Captain', toteamtemplate = OTHER_TEAM_TEMPLATE}),
			}})

			assert.are_same({'Alice_2021-01-01_Standin_former', 'Alice_2022-01-01_Captain_former'}, result.objectNames)
			assert.are_equal('2022-01-01', result.rows['Alice_2021-01-01_Standin_former'].leavedate)
			assert.are_equal('2022-06-01', result.rows['Alice_2022-01-01_Captain_former'].leavedate)
		end)

		it('records the inactive date of a stint that ended inactive', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2022-01-01'),
				change('2022-03-01', {role2 = 'Inactive'}),
				leave('2022-06-01', {role1 = 'Inactive'}),
			}})

			assert.are_same({'Alice_2022-01-01__former'}, result.objectNames)
			local row = result.rows['Alice_2022-01-01__former']
			assert.are_equal('2022-01-01', row.joindate)
			assert.are_equal('2022-03-01', row.inactivedate)
			assert.are_equal('2022-06-01', row.leavedate)
			-- the table switches to former inactive, which is what adds the Inactive Date column
			assert.is_truthy(result.html:find('<th>Inactive Date</th>', 1, true))
		end)

		it('drops a duplicate join and flags the page', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2021-01-01'),
				join('2021-06-01'),
				leave('2022-06-01'),
			}})

			assert.are_same({'Alice_2021-01-01__former'}, result.objectNames)
			assert.are_same({'SquadAuto with invalid player history'}, result.categories)
		end)

		it('drops a leave without a join and flags the page', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				leave('2022-06-01'),
			}})

			assert.are_same({}, result.objectNames)
			assert.are_same({'SquadAuto with invalid player history'}, result.categories)
		end)

		it('leaves an unfinished stint out of the table', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {join('2022-01-01')}})
			assert.are_same({}, result.objectNames)
		end)

		it('defaults the title to Former Players for player tables', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2022-01-01'),
				leave('2022-06-01'),
			}})
			assert.is_truthy(result.html:find('<div class="table2__title">Former Players</div>', 1, true))
		end)

		it('splits stints from different years into tabs', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2021-01-01'),
				leave('2021-06-01'),
				join('2022-01-01'),
				leave('2022-06-01'),
			}})

			assert.are_equal(2, #result.objectNames)
			assert.is_truthy(result.html:find('2021', 1, true))
			assert.is_truthy(result.html:find('2022', 1, true))
			assert.is_truthy(result.html:find('tabs-dynamic', 1, true))
		end)

		it('does not use tabs when every stint ended in the same year', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2021-01-01'),
				leave('2022-01-01'),
				join('2022-02-01'),
				leave('2022-06-01'),
			}})

			assert.are_equal(2, #result.objectNames)
			assert.is_nil(result.html:find('tabs-dynamic', 1, true))
		end)
	end)

	describe('next team', function()
		it('looks up the team a person joined next when the leave transfer has none', function()
			local result = runAuto({status = 'former', type = 'player'}, {
				transfers = {join('2022-01-01'), leave('2022-06-01')},
				nextTeam = {toteamtemplate = OTHER_TEAM_TEMPLATE, role2 = 'Coach', date = '2022-08-01'},
			})

			local row = result.rows['Alice_2022-01-01__former']
			assert.are_equal('Team Liquid', row.newteam)
			assert.are_equal('Coach', row.newteamrole)
			assert.are_equal('2022-08-01', row.extradata.newteamdate)

			local lookup = require('Module:Array').filter(result.queries, function(query)
				return query.query == 'toteamtemplate, role2, date'
			end)[1]
			assert.is_truthy(lookup.conditions:find('[[date::>2022-06-01]]', 1, true))
			assert.is_truthy(lookup.conditions:find('[[toteamtemplate::!]]', 1, true))
		end)

		it('does not look one up when the leave transfer already names a team', function()
			local result = runAuto({status = 'former', type = 'player'}, {
				transfers = {join('2022-01-01'), leave('2022-06-01', {toteamtemplate = OTHER_TEAM_TEMPLATE})},
				nextTeam = {toteamtemplate = 'mouz 2021', role2 = 'Coach', date = '2022-08-01'},
			})

			assert.are_equal('Team Liquid', result.rows['Alice_2022-01-01__former'].newteam)
			local lookups = require('Module:Array').filter(result.queries, function(query)
				return query.query == 'toteamtemplate, role2, date'
			end)
			assert.are_equal(0, #lookups)
		end)
	end)

	describe('secondary teams', function()
		it('follows the team through the secondary team fields', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				transfer{
					date = '2022-01-01',
					extradata = {toteamsectemplate = TEAM_TEMPLATE, role2sec = 'Standin'},
					toteamtemplate = OTHER_TEAM_TEMPLATE,
					role2 = 'Coach',
				},
			}})

			assert.are_same({'Alice_2022-01-01_Standin_active'}, result.objectNames)
		end)

		it('skips a transfer that does not change anything for this team', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01', {role2 = 'Standin'}),
				-- the person moved between two other teams while staying a Stand-in here
				transfer{
					date = '2022-06-01',
					fromteamtemplate = OTHER_TEAM_TEMPLATE,
					toteamtemplate = 'team liquid 2023',
					extradata = {fromteamsectemplate = TEAM_TEMPLATE, toteamsectemplate = TEAM_TEMPLATE,
						role1sec = 'Standin', role2sec = 'Standin'},
				},
			}})

			assert.are_same({'Alice_2022-01-01_Standin_active'}, result.objectNames)
		end)
	end)

	describe('loans', function()
		it('keeps the loan role but does not record which team lent the person out', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				transfer{
					date = '2022-01-01',
					fromteamtemplate = OTHER_TEAM_TEMPLATE,
					toteamtemplate = TEAM_TEMPLATE,
					role1 = 'Standin',
					role2 = 'Loan',
				},
			}})

			local row = result.rows['Alice_2022-01-01_Loan_active']
			assert.is_truthy(row)
			assert.are_equal('Loan', row.role)
			-- the lending team is only picked up when it is one of this team's own templates, so a
			-- loan in from another team leaves both loan fields empty
			assert.is_nil(row.extradata.loanedto)
			assert.is_nil(row.extradata.loanedtorole)
		end)

		it('records the loan when the person stays on the same team template', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2021-01-01'),
				change('2022-01-01', {role1 = 'Standin', role2 = 'Loan'}),
			}})

			local row = result.rows['Alice_2022-01-01_Loan_active']
			assert.is_truthy(row)
			assert.are_equal(TEAM_TEMPLATE, row.extradata.loanedto)
			assert.are_equal('Standin', row.extradata.loanedtorole)
		end)
	end)

	describe('player and staff tables', function()
		it('keeps staff roles out of the player table', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {
				join('2022-01-01', {player = 'Alice', role2 = 'Coach'}),
			}})
			assert.are_same({}, result.objectNames)
		end)

		it('keeps player roles out of the staff table', function()
			local result = runAuto({status = 'active', type = 'staff'}, {transfers = {
				join('2022-01-01', {role2 = 'Standin'}),
			}})
			assert.are_same({}, result.objectNames)
		end)

		it('puts staff roles in the staff table', function()
			local result = runAuto({status = 'active', type = 'staff'}, {transfers = {
				join('2022-01-01', {role2 = 'Coach'}),
			}})
			assert.are_same({'Alice_2022-01-01_Coach_active'}, result.objectNames)
			assert.are_equal('staff', result.rows['Alice_2022-01-01_Coach_active'].type)
		end)

		it('classifies an unknown role or position as staff', function()
			-- unknown roles are assumed to be non-player, and the position is classified the same way,
			-- so a free text position moves a person out of the player table
			local transfers = {join('2022-01-01', {extradata = {position = 'Mid'}})}
			assert.are_same({}, runAuto({status = 'active', type = 'player'}, {transfers = transfers}).objectNames)

			local staffResult = runAuto({status = 'active', type = 'staff'}, {transfers = transfers})
			assert.are_same({'Alice_2022-01-01__active'}, staffResult.objectNames)
			assert.are_equal('Mid', staffResult.rows['Alice_2022-01-01__active'].position)
		end)

		it('puts someone without any role in the player table', function()
			local result = runAuto({status = 'active', type = 'player'}, {transfers = {join('2022-01-01')}})
			assert.are_same({'Alice_2022-01-01__active'}, result.objectNames)
		end)

		it('takes every entry for an inactive table regardless of role', function()
			-- inactive entries are preselected by the transfer walk, so the role filter is skipped
			local result = runAuto({status = 'inactive', type = 'player'}, {transfers = {
				join('2022-01-01', {role2 = 'Coach'}),
				change('2022-06-01', {role1 = 'Coach', role2 = 'Inactive'}),
			}})
			assert.are_same({'Alice_2022-01-01_Coach_inactive'}, result.objectNames)
		end)
	end)

	describe('manual rows', function()
		it('adds a manual staff row to a staff table', function()
			local result = runAuto({
				status = 'active',
				type = 'staff',
				'{"id":"Bob","role":"Manager","flag":"de","joindate":"2020-01-01"}',
			}, {transfers = {}})

			assert.are_same({'Bob_2020-01-01_Manager_active'}, result.objectNames)
			local row = result.rows['Bob_2020-01-01_Manager_active']
			assert.are_equal('Germany', row.nationality)
			assert.are_equal('Manager', row.role)
		end)

		it('treats a manual row without a role as an override of the transfer data', function()
			local result = runAuto({
				status = 'active',
				type = 'player',
				'{"id":"Alice","name":"Alice Smith","flag":"de"}',
			}, {transfers = {join('2022-01-01')}})

			assert.are_same({'Alice_2022-01-01__active'}, result.objectNames)
			local row = result.rows['Alice_2022-01-01__active']
			assert.are_equal('Alice Smith', row.name)
			assert.are_equal('Germany', row.nationality)
		end)

		it('treats a manual row on a player table as an override even when it has a role', function()
			local result = runAuto({
				status = 'active',
				type = 'player',
				'{"id":"Alice","role":"Manager"}',
			}, {transfers = {join('2022-01-01')}})

			-- the role is not applied, the row only enriches id/name/flag/faction/captain
			assert.are_same({'Alice_2022-01-01__active'}, result.objectNames)
			assert.are_equal('', result.rows['Alice_2022-01-01__active'].role)
		end)

		it('requires an identifier on a manual row', function()
			assert.has_error(function()
				runAuto({status = 'active', type = 'staff', '{"role":"Manager"}'}, {transfers = {}})
			end)
		end)
	end)

	describe('enrichment from the player record', function()
		it('fills in id, flag and name that the transfers did not carry', function()
			local result = runAuto({status = 'active', type = 'player'}, {
				transfers = {transfer{
					date = '2022-01-01',
					toteamtemplate = TEAM_TEMPLATE,
					nationality = '',
					extradata = {displayname = ''},
				}},
				person = {pagename = 'Alice', id = 'AliceTag', nationality = 'de', name = 'Alice Smith'},
			})

			local row = result.rows['Alice_2022-01-01__active']
			assert.are_equal('AliceTag', row.id)
			assert.are_equal('Germany', row.nationality)
			assert.are_equal('Alice Smith', row.name)
		end)

		it('does not override what the transfers already provided', function()
			local result = runAuto({status = 'active', type = 'player'}, {
				transfers = {join('2022-01-01', {extradata = {displayname = 'AliceTag'}})},
				person = {pagename = 'Alice', id = 'Other', nationality = 'de', name = 'Alice Smith'},
			})

			-- the object name is built from the page name, the display name only feeds the id
			local row = result.rows['Alice_2022-01-01__active']
			assert.is_truthy(row)
			assert.are_equal('AliceTag', row.id)
			assert.are_equal('Sweden', row.nationality)
			assert.are_equal('Alice Smith', row.name)
		end)
	end)

	describe('sorting', function()
		it('sorts former stints by leave date', function()
			local result = runAuto({status = 'former', type = 'player'}, {transfers = {
				join('2022-02-01', {player = 'Bob', extradata = {displayname = 'Bob'}}),
				leave('2022-09-01', {player = 'Bob', extradata = {displayname = 'Bob'}}),
				join('2022-01-01', {extradata = {displayname = 'Alice'}}),
				leave('2022-03-01', {extradata = {displayname = 'Alice'}}),
			}})

			assert.is_true(result.html:find('Alice', 1, true) < result.html:find('Bob', 1, true))
		end)
	end)
end)

insulate('Squad/Auto on a wiki without the standardized auto squad', function()
	setup(function() SetActiveWiki('dota2') end)
	teardown(function() SetActiveWiki() end)

	it('hands over to the legacy module', function()
		local SquadAuto = require('Module:Squad/Auto')
		-- Module:SquadAuto is a per wiki legacy module that does not exist here, so importing it fails
		assert.has_error(function()
			SquadAuto.run{team = 'MOUZ', status = 'former', type = 'player'}
		end)
	end)
end)
