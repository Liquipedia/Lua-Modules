---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateMatch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local TemplateMatch = {}

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local json = require('Module:Json')
local utils = require('Module:LuaUtils')--only needed for utils.log

local Match = Lua.import('Module:Match', {requireDevIfEnabled = true})

-- store match to a var to later store them to LPDB
function TemplateMatch.storeVar(args)
	local matchNum = tonumber(Variables.varDefault('numTempMatch', 0)) + 1
	Variables.varDefine('numTempMatch', matchNum)
	Variables.varDefine('tempMatch' .. matchNum, json.stringify(args))
end

-- store matches from vars to LPDB
function TemplateMatch.storeVarsToLPDB()
	local matchNum = tonumber(Variables.varDefault('numTempMatch', 0))
	utils.log('Storing ' .. matchNum .. ' template matches to LPDB')

	-- parse all matches and find out which matches are referenced
	-- also parse bracketdata
	local matches = {}
	local referencedIds = {}
	for m = 1, matchNum do
		local jsonEncodedData = Variables.varDefault('tempMatch' .. m)
		if jsonEncodedData ~= nil then
			local data = json.parse(jsonEncodedData)
			local bracketData = json.parse(data.bracketdata or '{}')
			data.bracketdata = bracketData
			referencedIds[TemplateMatch._getTrueID(bracketData.tolower)] = true
			referencedIds[TemplateMatch._getTrueID(bracketData.toupper)] = true

			matches[data.matchid] = data
		end
	end

	-- find root matches and set the root value there
	local rootMatches = {}
	for _, match in pairs(matches) do
		if not referencedIds[match.matchid] and not String.startsWith(match.matchid, 'Rx') then
			match.bracketdata.root = 'true'
			table.insert(rootMatches, match.matchid)
		end
	end

	-- set bracket index for matches
	--applied is the maximum of all bracketIndex's
	--it is needed to deterimne if bracketIndex == 2 means "mid" or "lower"
	local applied = 0
	for _, id in Table.iter.spairs(rootMatches, function(tab, a, b) return tab[a] < tab[b] end) do
		matches, applied = TemplateMatch._recursiveSetBracketIndex(matches, id, false, applied)
	end

	-- set bracket section for matches
	for id, match in pairs(matches) do
		local bracketIndex = tonumber(match.bracketdata.bracketindex)
		if bracketIndex == 1 then
			match.bracketdata.bracketsection = 'upper'
		elseif bracketIndex == 2 then
			if applied == 3 then
				match.bracketdata.bracketsection = 'mid'
			else
				match.bracketdata.bracketsection = 'lower'
			end
		elseif bracketIndex == 3 then
			match.bracketdata.bracketsection = 'lower'
		end
		match.bracketdata.bracketindex = nil
		matches[id] = match
	end

	-- set alternate ids for matches (R1M1 -> U1M1, etc. L for lower and M for mid)
	-- evaluate for later

	-- store matches
	for _, match in pairs(matches) do
		Match.store(match)
	end
end

local pagename = mw.title.getCurrentTitle().text
function TemplateMatch._getTrueID(id)
	if id == nil then
		return nil
	else
		return id:gsub(pagename:gsub('([^%w])', '%%%1') .. '_', '')
	end
end

-- recursively sets which bracket the match is in
function TemplateMatch._recursiveSetBracketIndex(matches, id, headerchild, applied)
	if Logic.isEmpty(id) then
		return matches, applied
	end
	id = TemplateMatch._getTrueID(id)
	local match = matches[id]
	if not Logic.isEmpty(match.bracketdata.header) and headerchild ~= true then
		applied = applied + 1
		headerchild = true
	end
	match.bracketdata.bracketindex = applied
	matches[id] = match
	matches, applied = TemplateMatch._recursiveSetBracketIndex(matches, match.bracketdata.toupper, headerchild, applied)
	local lowerHeaderchild = headerchild
	if not String.isEmpty(match.bracketdata.toupper) then
		lowerHeaderchild = false
	end
	matches, applied = TemplateMatch._recursiveSetBracketIndex(
		matches, match.bracketdata.tolower, lowerHeaderchild, applied)
	return matches, applied
end

return Class.export(TemplateMatch)
