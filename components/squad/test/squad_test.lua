
---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local Squad = Lua.import('Module:Squad', {requireDevIfEnabled = true})
local SquadRow = Lua.import('Module:Squad/Row', {requireDevIfEnabled = true})
local LpdbMock = Lua.import('Module:Mock/Lpdb', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testRow()
	LpdbMock.setUp()

	local row = SquadRow()
	row	:id{'Baz', 'se'}
		:name{'Foo Bar'}
		:role{}
		:date('2022-01-01', 'Join Date:&nbsp;', 'joindate')
		:date('2022-03-03', 'Inactive Date:&nbsp;', 'inactivedate')
		:date('2022-05-01', 'Leave Date:&nbsp;', 'leavedate')
		:newteam{
			newteam = 'Sweden',
			leavedate = '2022-05-01'
		}

	local createdRow = row:create('object_name')

	self:assertEquals(
		'<tr class="Player"><td class="ID">\'\'\'<span style="white-space:pre">[[Baz]]</span>\'\'\'</td>' ..
		'<td></td><td class="Name"><div class="MobileStuff">(</div><div class="MobileStuff">)</div></td>' ..
		'<td class="Position"></td><td class="Date"><div class="MobileStuffDate">Join Date:&nbsp;</div>' ..
		'<div class="Date">\'\'2022-01-01\'\'</div></td><td class="Date">' ..
		'<div class="MobileStuffDate">Inactive Date:&nbsp;</div><div class="Date">\'\'2022-03-03\'\'</div></td>' ..
		'<td class="Date"><div class="MobileStuffDate">Leave Date:&nbsp;</div>' ..
		'<div class="Date">\'\'2022-05-01\'\'</div></td><td class="NewTeam"><div class="MobileStuff">' ..
		'<i class="fa fa-long-arrow-right" aria-hidden="true"></i>&nbsp;</div>' ..
		'<span data-highlightingclass="Team Sweden" class="team-template-team-standard">' ..
		'<span class="team-template-image-icon team-template-lightmode">' ..
		'[[File:Flag of Sweden 4 by 3.png|100x50px|middle|Team Sweden|link=Team Sweden]]</span>' ..
		'<span class="team-template-image-icon team-template-darkmode">' ..
		'[[File:Flag of Sweden 4 by 3.png|100x50px|middle|Team Sweden|link=Team Sweden]]</span> '..
		'<span class="team-template-text">[[Team Sweden|Team Sweden]]</span></span></td></tr>',
		tostring(createdRow)
	)

	LpdbMock.tearDown()
end

function suite:testHeader()
	local squad = Squad():init{}:title():header():create()

	self:assertEquals(
		'<div class="table-responsive" style="margin-bottom:10px;padding-bottom:0px">' ..
		'<table class="wikitable wikitable-striped roster-card">' ..
		'<tr><th class="large-only" colspan="1">Active Squad</th>'..
		'<th class="large-only roster-title-row2-border" colspan="10">Active Squad</th></tr>' ..
		'<tr class="HeaderRow"><th class="divCell">ID</th><th></th><th class="divCell">Name</th><th>' ..
		'</th><th class="divCell">Join Date</th></tr>' ..
		'</table></div>',
		tostring(squad)
	)
end

return suite
