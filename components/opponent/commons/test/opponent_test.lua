---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent/testcases
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ScribuntoUnit = require('Module:ScribuntoUnit')

local config = Lua.import('Module:Opponent/testcases/config', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local suite = ScribuntoUnit:new()

function suite:testTypeIsParty()
	self:assertTrue(Opponent.typeIsParty(Opponent.solo))
	self:assertTrue(Opponent.typeIsParty(Opponent.duo))
	self:assertTrue(Opponent.typeIsParty(Opponent.trio))
	self:assertTrue(Opponent.typeIsParty(Opponent.quad))
	self:assertFalse(Opponent.typeIsParty(Opponent.literal))
	self:assertFalse(Opponent.typeIsParty(Opponent.team))
	self:assertFalse(Opponent.typeIsParty())
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertFalse(Opponent.typeIsParty('someBs'))
end

function suite:testPartySize()
	self:assertEquals(1, Opponent.partySize(Opponent.solo))
	self:assertEquals(2, Opponent.partySize(Opponent.duo))
	self:assertEquals(3, Opponent.partySize(Opponent.trio))
	self:assertEquals(4, Opponent.partySize(Opponent.quad))
	self:assertEquals(nil, Opponent.partySize(Opponent.literal))
	self:assertEquals(nil, Opponent.partySize(Opponent.team))
	self:assertEquals(nil, Opponent.partySize())
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertEquals(nil, Opponent.partySize('someBs'))
end

function suite:testBlank()
	self:assertDeepEquals(config.blankSolo, Opponent.blank(Opponent.solo))
	self:assertDeepEquals(config.blankDuo, Opponent.blank(Opponent.duo))
	self:assertDeepEquals(config.blankTeam, Opponent.blank(Opponent.team))
	self:assertDeepEquals(config.blankLiteral, Opponent.blank(Opponent.literal))
	self:assertDeepEquals(config.blankLiteral, Opponent.blank())
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertDeepEquals(config.blankLiteral, Opponent.blank('someBs'))
end

function suite:testTbd()
	self:assertDeepEquals(config.tbdSolo, Opponent.tbd(Opponent.solo))
	self:assertDeepEquals(config.tbdDuo, Opponent.tbd(Opponent.duo))
	self:assertDeepEquals(config.tbdTeam, Opponent.tbd(Opponent.team))
	self:assertDeepEquals(config.tbdLiteral, Opponent.tbd(Opponent.literal))
	self:assertDeepEquals(config.tbdLiteral, Opponent.tbd())
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertDeepEquals(config.tbdLiteral, Opponent.tbd('someBs'))
end

function suite:testIsTbd()
	self:assertTrue(Opponent.isTbd(config.byeLiteral))
	self:assertFalse(Opponent.isTbd(config.byeTeam))
	self:assertTrue(Opponent.isTbd(config.blankLiteral))
	self:assertTrue(Opponent.isTbd(config.blankSolo))
	self:assertTrue(Opponent.isTbd(config.blankDuo))
	self:assertTrue(Opponent.isTbd(config.blankTeam))
	self:assertTrue(Opponent.isTbd(config.tbdLiteral))
	self:assertTrue(Opponent.isTbd(config.tbdSolo))
	self:assertTrue(Opponent.isTbd(config.tbdDuo))
	self:assertTrue(Opponent.isTbd(config.filledLiteral))
	self:assertFalse(Opponent.isTbd(config.filledTeam))
	self:assertFalse(Opponent.isTbd(config.filledSolo))
	self:assertFalse(Opponent.isTbd(config.filledDuo))
	self:assertThrows(Opponent.isTbd)--misisng input
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertThrows(function() return Opponent.isTbd('someBs') end)
end

function suite:testIsEmpty()
	self:assertFalse(Opponent.isEmpty(config.byeLiteral))
	self:assertFalse(Opponent.isEmpty(config.byeTeam))
	self:assertTrue(Opponent.isEmpty(config.blankLiteral))
	self:assertTrue(Opponent.isEmpty(config.blankSolo))
	self:assertTrue(Opponent.isEmpty(config.blankDuo))
	self:assertTrue(Opponent.isEmpty(config.emptyTeam))
	self:assertFalse(Opponent.isEmpty(config.blankTeam))
	self:assertFalse(Opponent.isEmpty(config.tbdLiteral))
	self:assertFalse(Opponent.isEmpty(config.tbdSolo))
	self:assertFalse(Opponent.isEmpty(config.tbdDuo))
	self:assertFalse(Opponent.isEmpty(config.filledLiteral))
	self:assertFalse(Opponent.isEmpty(config.filledTeam))
	self:assertFalse(Opponent.isEmpty(config.filledSolo))
	self:assertFalse(Opponent.isEmpty(config.filledDuo))
	self:assertTrue(Opponent.isEmpty())
	self:assertTrue(Opponent.isEmpty('someBs'))--invalid input
end

function suite:testIsBye()
	self:assertFalse(Opponent.isBye(config.blankLiteral))
	self:assertFalse(Opponent.isBye(config.blankSolo))
	self:assertFalse(Opponent.isBye(config.blankDuo))
	self:assertFalse(Opponent.isBye(config.emptyTeam))
	self:assertFalse(Opponent.isBye(config.blankTeam))
	self:assertFalse(Opponent.isBye(config.tbdLiteral))
	self:assertFalse(Opponent.isBye(config.tbdSolo))
	self:assertFalse(Opponent.isBye(config.tbdDuo))
	self:assertFalse(Opponent.isBye(config.filledLiteral))
	self:assertFalse(Opponent.isBye(config.filledTeam))
	self:assertFalse(Opponent.isBye(config.filledSolo))
	self:assertFalse(Opponent.isBye(config.filledDuo))
	self:assertTrue(Opponent.isBye(config.byeLiteral))
	self:assertTrue(Opponent.isBye(config.byeTeam))
	self:assertThrows(Opponent.isBye)
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertFalse(Opponent.isBye('someBs'))
end

function suite:testReadType()
	---intended missing input
	---@diagnostic disable-next-line: missing-parameter
	self:assertEquals(nil, Opponent.readType())
	self:assertEquals(nil, Opponent.readType('someBs'))
	self:assertEquals(Opponent.solo, Opponent.readType('solo'))
	self:assertEquals(Opponent.duo, Opponent.readType('duo'))
	self:assertEquals(Opponent.trio, Opponent.readType('trio'))
	self:assertEquals(Opponent.quad, Opponent.readType('quad'))
	self:assertEquals(Opponent.team, Opponent.readType('team'))
	self:assertEquals(Opponent.literal, Opponent.readType('literal'))
end

function suite:testCoerce()
	local coerce = function(opponent)
		Opponent.coerce(opponent)
		return opponent
	end

	self:assertDeepEquals(config.blankLiteral, coerce{})
	self:assertDeepEquals(config.blankLiteral, coerce{type = Opponent.literal})
	self:assertDeepEquals(config.blankTeam, coerce{type = Opponent.team})
	self:assertDeepEquals(config.blankSolo, coerce{type = Opponent.solo})
	self:assertDeepEquals(config.blankDuo, coerce{type = Opponent.duo})
	self:assertDeepEquals({type = Opponent.duo, players = {{displayName = 'test'}, {displayName = ''}}},
		coerce{type = Opponent.duo, players = {{displayName = 'test'}}})
end

function suite:testToName()
	self:assertEquals('test', Opponent.toName(config.filledLiteral))
	self:assertEquals('test', Opponent.toName(config.filledSolo))
	self:assertEquals('test / test2', Opponent.toName(config.filledDuo))
	self:assertThrows(Opponent.toName)
	---intended bad input
	---@diagnostic disable-next-line: param-type-mismatch
	self:assertEquals(nil, Opponent.toName('someBs'))
	--can not test team type due to missing team templates on commons
end

function suite:testReadOpponentArgs()
	self:assertDeepEquals({type = Opponent.solo, players = {
			{displayName = 'test', flag = 'Germany', pageName = 'testLink', team = 'mouz'}
		}}, Opponent.readOpponentArgs{type = Opponent.solo, p1 = 'test', flag = 'de', link = 'testLink', team = 'mouz'})
	self:assertDeepEquals({type = Opponent.duo, players = {
				{displayName = 'test', flag = 'Germany', pageName = 'testLink', team = 'mouz'},
				{displayName = 'test2', flag = 'Austria'},
			}}, Opponent.readOpponentArgs{p1 = 'test', p1flag = 'de', p1link = 'testLink', p1team = 'mouz',
		p2 = 'test2', p2flag = 'at', type = Opponent.duo})
	self:assertDeepEquals({name = 'test', type = Opponent.literal},
		Opponent.readOpponentArgs{type = Opponent.literal, name = 'test'})
	self:assertDeepEquals({template = 'test', type = Opponent.team},
		Opponent.readOpponentArgs{type = Opponent.team, template = 'test'})
	self:assertDeepEquals({name = 'test', type = Opponent.literal},
		Opponent.readOpponentArgs{type = Opponent.literal, 'test'})
	self:assertDeepEquals({template = 'test', type = Opponent.team},
		Opponent.readOpponentArgs{type = Opponent.team, 'test'})
end

function suite:testFromMatch2Record()
	self:assertDeepEquals({name = '', type = Opponent.literal},
		Opponent.fromMatch2Record(config.exampleMatch2RecordLiteral))
	self:assertDeepEquals({template = 'exon march 2020', type = Opponent.team},
		Opponent.fromMatch2Record(config.exampleMatch2RecordTeam))
	self:assertDeepEquals({type = Opponent.solo, players = {
			{displayName = 'Krystianer', flag = 'Poland', pageName = 'Krystianer'}}},
		Opponent.fromMatch2Record(config.exampleMatch2RecordSolo))
	self:assertDeepEquals({type = Opponent.duo, players = {
			{displayName = 'Semper', flag = 'Canada', pageName = 'Semper'},
			{displayName = 'Jig', flag = 'Canada', pageName = 'Jig'},
		}}, Opponent.fromMatch2Record(config.exampleMatch2RecordDuo))
end

function suite:testToLpdbStruct()
	self:assertDeepEquals({opponentname = '', opponenttype = Opponent.literal},
		Opponent.toLpdbStruct(Opponent.fromMatch2Record(config.exampleMatch2RecordLiteral)--[[@as standardOpponent]]))
	self:assertDeepEquals({opponentname = 'Krystianer', opponenttype = Opponent.solo, opponentplayers = {
			p1 = 'Krystianer',
			p1dn = 'Krystianer',
			p1flag = 'Poland',
		}}, Opponent.toLpdbStruct(Opponent.fromMatch2Record(config.exampleMatch2RecordSolo)--[[@as standardOpponent]]))
	self:assertDeepEquals({opponentname = 'Semper / Jig', opponenttype = Opponent.duo, opponentplayers = {
			p1 = 'Semper',
			p1dn = 'Semper',
			p1flag = 'Canada',
			p2 = 'Jig',
			p2dn = 'Jig',
			p2flag = 'Canada',
		}}, Opponent.toLpdbStruct(Opponent.fromMatch2Record(config.exampleMatch2RecordDuo)--[[@as standardOpponent]]))
	--can not test for team opponent due to missing team templates
end

function suite:testFromLpdbStruct()
	local opponent = Opponent.fromMatch2Record(config.exampleMatch2RecordLiteral) --[[@as standardOpponent]]
	self:assertDeepEquals(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
	opponent = Opponent.fromMatch2Record(config.exampleMatch2RecordSolo) --[[@as standardOpponent]]
	self:assertDeepEquals(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
	opponent = Opponent.fromMatch2Record(config.exampleMatch2RecordDuo) --[[@as standardOpponent]]
	self:assertDeepEquals(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
	--can not test for team opponent due to missing team templates
end

--not testing `resolve` due to missing team templates and lpdb data

return suite
