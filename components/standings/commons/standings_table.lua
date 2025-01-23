---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local StandingsParseLpdb = Lua.import('Module:Standings/Parse/Lpdb')
local StandingsParser = Lua.import('Module:Standings/Parser')
local StandingsStorage = Lua.import('Module:Standings/Storage')

local Display = Lua.import('Module:Widget/Standings')

local StandingsTable = {}

---@param frame Frame
---@return Widget
function StandingsTable.fromTemplate(frame)
	local args = Arguments.getArgs(frame)
	local tableType = args.tabletype
	if tableType ~= 'ffa' then
		error('Unknown Standing Table Type')
	end
	local title = args.title

	local parsedData = StandingsParseWiki.parseWikiInput(args)
	local rounds = parsedData.rounds
	local opponents = parsedData.opponents
	local bgs = parsedData.bgs
	local matches = parsedData.matches

	if Logic.readBoolOrNil(args.import) == false then
		return StandingsTable.ffa(rounds, opponents, bgs, title, matches)
	end

	opponents = StandingsParseLpdb.importFromMatches(rounds)
	return StandingsTable.ffa(rounds, opponents, bgs, title, matches)
end

---@param rounds any
---@param opponents any
---@param bgs any
---@param title any
---@param matches any
---@return Widget
function StandingsTable.ffa(rounds, opponents, bgs, title, matches)
	local standingsTable = StandingsParser.parse(rounds, opponents, bgs, title, matches)
	StandingsStorage.run(standingsTable)
	return Display{pageName = mw.title.getCurrentTitle().text, standingsIndex = standingsTable.standingsindex}
end

return StandingsTable
