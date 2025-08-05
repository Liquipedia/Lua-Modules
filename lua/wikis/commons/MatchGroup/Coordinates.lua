---
-- @Liquipedia
-- page=Module:MatchGroup/Coordinates
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Iterator = Lua.import('Module:Iterator')
local MathUtil = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TreeUtil = Lua.import('Module:TreeUtil')

---@class MatchGroupCoordinatesRoundProps
---@field depth integer
---@field depthCount integer
---@field roundIndex integer
---@field matchIndexInRound integer

local MatchGroupCoordinates = {}

---@param bracketDatasById table<string, MatchGroupUtilBracketBracketData>
---@param start string
---@return function
function MatchGroupCoordinates.dfsFrom(bracketDatasById, start)
	return TreeUtil.dfs(
		function(matchId)
			return bracketDatasById[matchId].lowerMatchIds
		end,
		start
	)
end

---@param bracket MatchGroupUtilBracket
---@return function
function MatchGroupCoordinates.dfs(bracket)
	return Iterator.flatMap(function(_, rootMatchId)
		return MatchGroupCoordinates.dfsFrom(bracket.bracketDatasById, rootMatchId)
	end, ipairs(bracket.rootMatchIds))
end

---@param bracketDatasById table<string, MatchGroupUtilBracketData>
---@return table<string, string>
function MatchGroupCoordinates.computeUpperMatchIds(bracketDatasById)
	local upperMatchIds = {}
	for matchId, bracketData in pairs(bracketDatasById) do
		for _, lowerMatchId in ipairs(bracketData.lowerMatchIds) do
			upperMatchIds[lowerMatchId] = matchId
		end
	end
	return upperMatchIds
end

---@param bracket MatchGroupUtilBracket
---@return string[][]
---@return table<string, integer>
function MatchGroupCoordinates.computeSections(bracket)
	local sectionIxs = {}
	local sections = {}
	for matchId in MatchGroupCoordinates.dfs(bracket) do
		local bracketData = bracket.bracketDatasById[matchId]
		local upperMatch = bracketData.upperMatchId and bracket.bracketDatasById[bracketData.upperMatchId]
		local isNewSection = bracketData.header ~= nil
			and (not upperMatch or matchId ~= upperMatch.lowerMatchIds[1])
			and not String.endsWith(matchId, 'RxMTP')
		if isNewSection then
			table.insert(sections, {})
		end
		table.insert(sections[#sections], matchId)
		sectionIxs[matchId] = #sections
	end
	return sections, sectionIxs
end

---@param bracketDatasById table<string, MatchGroupUtilBracketData>
---@param startMatchId string
---@return table<string, integer>
---@return integer
function MatchGroupCoordinates.computeDepthsFrom(bracketDatasById, startMatchId)
	local depths = {}
	local maxDepth = -1
	local function visit(matchId, depth)
		local bracketData = bracketDatasById[matchId]
		depths[matchId] = depth
		maxDepth = math.max(maxDepth, depth + bracketData.skipRound)
		for _, lowerMatchId in ipairs(bracketData.lowerMatchIds) do
			visit(lowerMatchId, depth + 1 + bracketData.skipRound)
		end
	end
	visit(startMatchId, 0)
	return depths, maxDepth + 1
end

---@param bracket MatchGroupUtilBracket
---@param sectionIxs table<string, integer>
---@return table<string, integer>
function MatchGroupCoordinates.computeSemanticDepths(bracket, sectionIxs)
	local depths = {}
	local function visit(matchId, depth)
		local lowerMatchIds = bracket.bracketDatasById[matchId].lowerMatchIds
		local lastLowerId = #lowerMatchIds and lowerMatchIds[#lowerMatchIds]
		local isGrandFinal = lastLowerId and sectionIxs[lastLowerId] ~= sectionIxs[matchId]
		if isGrandFinal then
			depth = depth - 1
		end
		depths[matchId] = depth
		for _, lowerMatchId in ipairs(lowerMatchIds) do
			visit(lowerMatchId, depth + 1)
		end
	end

	local groups, _ = Array.groupBy(
		Array.filter(bracket.rootMatchIds, function(matchId) return not String.endsWith(matchId, 'RxMTP') end),
		function(rootMatchId) return sectionIxs[rootMatchId] end
	)
	for _, group in ipairs(groups) do
		local initialDepth = MathUtil.ilog2(#group) + 1
		for _, rootMatchId in ipairs(group) do
			visit(rootMatchId, initialDepth)
		end
	end

	return depths
end

---@param bracket MatchGroupUtilBracket
---@return string[][]
---@return table<string, MatchGroupCoordinatesRoundProps>
function MatchGroupCoordinates.computeRounds(bracket)
	local rounds = {}
	local roundPropsByMatchId = {}
	for _, rootMatchId in ipairs(bracket.rootMatchIds) do
		local depths, depthCount = MatchGroupCoordinates.computeDepthsFrom(bracket.bracketDatasById, rootMatchId)
		for _ = #rounds + 1, depthCount do
			table.insert(rounds, {})
		end

		for matchId, depth in pairs(depths) do
			roundPropsByMatchId[matchId] = {
				depth = depth,
				depthCount = depthCount,
			}
		end
	end

	for _, rootMatchId in ipairs(bracket.rootMatchIds) do
		for matchId in MatchGroupCoordinates.dfsFrom(bracket.bracketDatasById, rootMatchId) do
			local roundProps = roundPropsByMatchId[matchId]

			-- All roots are left aligned, except the third place match which is right aligned
			local roundIndex = String.endsWith(matchId, 'RxMTP')
				and #rounds
				or roundProps.depthCount - roundProps.depth

			table.insert(rounds[roundIndex], matchId)
			roundProps.matchIndexInRound = #rounds[roundIndex]
			roundProps.roundIndex = roundIndex
		end
	end

	return rounds, roundPropsByMatchId
end

---@param sections string[][]
---@param roundPropsByMatchId table<string, MatchGroupCoordinatesRoundProps>
---@return table<string, integer>
function MatchGroupCoordinates.computeSemanticRounds(sections, roundPropsByMatchId)
	local semanticRoundIxs = {}

	for _, section in ipairs(sections) do
		local rounds = {}
		for _, matchId in ipairs(section) do
			local roundIndex = roundPropsByMatchId[matchId].roundIndex
			for _ = #rounds + 1, roundIndex do
				table.insert(rounds, {})
			end
			table.insert(rounds[roundIndex], matchId)
		end

		local semanticRoundIx = 1
		for _, round in ipairs(rounds) do
			for _, matchId in ipairs(round) do
				semanticRoundIxs[matchId] = semanticRoundIx
			end
			if #round ~= 0 then
				semanticRoundIx = semanticRoundIx + 1
			end
		end
	end

	return semanticRoundIxs
end

--[[
Computes properties of a match that describe its position within
the overall bracket.

Brackets are partitioned vertically into sections and roots, and
partitioned horizontally into rounds, columns, depths, and semantic
depths.

Section: Refers to the upper/lower bracket. Single-elim brackets
have one section, double-elim have two. More complicated brackets
can have 3+ sections. The grand finals match is considered to be
part of the upper bracket.

Root: Roots are matches that don't advance to another match in the
bracket. Roots vertically partition the bracket into non-connected
trees. A common use case for multiple roots is if a bracket is
truncated after a round. For example, 16SE-4Qual concludes after the
Ro8, so it has 4 roots.

Round: Rounds are semantic labeling of matches that tracks progress
within a tournament - higher rounds occur later in the tournament.
Brackets created with the bracket designer have matches of the same
round appear in one column. Custom brackets can have rounds not
aligned with columns. Match IDs are grouped by rounds.

Column: The bracket display uses a column layout for matches. The
columns partition the bracket horizontally. For most brackets, there
is no difference between columns and rounds.

Depth: The depth of a match is its distance from its root match.
Root matches have depth 0, each additional round increases the depth
by 1. Skipped rounds are included in the depth.

Semantic depth: The semantic depth encodes the X in "Round of X".
Specifically it is the base 2 logarithm of X, so that the finals has
semantic depth 1, semifinals 2, quarterfinals 3, etc. In double
elimination brackets, the upper bracket finals and lower bracket
finals have semantic depth 1, and the grand finals has semantic
depth 0. Ignores skipped rounds.

Fields reference:
coords.depth: 0-based depth (distance from root). Includes skipped rounds.
coords.depthCount = How deep the tree from the root extends. This is usually 1
more than the max depth, but can be deeper if there are childless matches with
skipRound set.
coords.matchIndexInRound: Index of the match within the round containing it.
coords.rootIndex: Index of the root whose tree contains the match.
coords.roundCount: Number of rounds in the bracket.
coords.roundIndex: Index of the round containing the match.
coords.sectionCount: Number of sections in the bracket.
coords.sectionIndex: Index of the section containing the match. (0=upper, 1=lower for double elim)
coords.semanticDepth: 1 for Finals, 2 for Semi-finals, 3 for Quarterfinals, etc. 0 for Grand Finals.
coords.semanticRoundIndex: Index of the round, skipping rounds that have no matches in the section

All indexes start from 1. coords.depth is 0-based and coords.semanticDepth is
1-based (0 denotes grand final). When stored to LPDB, the 1-based indexes are
converted to 0-based.
]]
---@param bracket MatchGroupUtilBracket
---@return {coordinatesByMatchId:table<string, MatchGroupUtilMatchCoordinates>, rounds:string[][], sections:string[][]}
function MatchGroupCoordinates.computeCoordinates(bracket)
	local sections, sectionIxs = MatchGroupCoordinates.computeSections(bracket)
	local rounds, roundPropsByMatchId = MatchGroupCoordinates.computeRounds(bracket)
	local semanticDepths = MatchGroupCoordinates.computeSemanticDepths(bracket, sectionIxs)
	local semanticRoundIxs = MatchGroupCoordinates.computeSemanticRounds(sections, roundPropsByMatchId)

	local coordinatesByMatchId = {}
	for rootIndex, rootMatchId in ipairs(bracket.rootMatchIds) do
		for matchId in MatchGroupCoordinates.dfsFrom(bracket.bracketDatasById, rootMatchId) do
			coordinatesByMatchId[matchId] = Table.merge(
				roundPropsByMatchId[matchId],
				{
					rootIndex = rootIndex,
					roundCount = #rounds,
					sectionCount = #sections,
					sectionIndex = sectionIxs[matchId],
					semanticDepth = semanticDepths[matchId],
					semanticRoundIndex = semanticRoundIxs[matchId],
				}
			)
		end
	end

	return {
		coordinatesByMatchId = coordinatesByMatchId,
		rounds = rounds,
		sections = sections,
	}
end

--[[
Returns a list of sections. Each section contains the matchIds for the matches
in that section of a bracket. The bracket must have coordinates data
previously computed.

The list is identical to the one returned by
MatchGroupCoordinates.computeSections.
]]
---@param bracket MatchGroupUtilBracket
---@return string[][]
function MatchGroupCoordinates.getSectionsFromCoordinates(bracket)
	return MatchGroupCoordinates.groupMatchIdsByField(bracket, 'sectionIndex')
end

--[[
Returns a list of rounds. Each round contains the matchIds for the matches in
that round of a bracket. The bracket must have coordinates data previously
computed.

The list is identical to the one returned by
MatchGroupCoordinates.computeRounds.
]]
---@param bracket MatchGroupUtilBracket
---@return string[][]
function MatchGroupCoordinates.getRoundsFromCoordinates(bracket)
	return MatchGroupCoordinates.groupMatchIdsByField(bracket, 'roundIndex')
end

---@param bracket MatchGroupUtilBracket
---@param fieldName string
---@return string[][]
function MatchGroupCoordinates.groupMatchIdsByField(bracket, fieldName)
	local countFieldName = fieldName:gsub('Index$', 'Count')
	local count = Table.getByPathOrNil(bracket.matches, {1, 'bracketData', 'coordinates', countFieldName}) or 0

	local byField = Array.map(Array.range(1, count), function() return {} end)
	for matchId in MatchGroupCoordinates.dfs(bracket) do
		local coordinates = bracket.coordinatesByMatchId[matchId]
		table.insert(byField[coordinates[fieldName]], matchId)
	end
	return byField
end

--[[
Compute the number of opponents from each round onward in a bracket.
Computes an array, where each key is round (column) of the bracket,
and the value is the number of opponents who are either in the
current round (column) or are seeded into a later round (column).
]]
---@param bracket MatchGroupUtilBracket
---@return integer[]
function MatchGroupCoordinates.computeBracketOpponentCounts(bracket)
	local countsByRound = MatchGroupCoordinates.computeRawCounts(bracket)

	-- Only include positive counts
	return Array.map(countsByRound, function(countsInRound)
		local sum = 0
		for _, count in ipairs(countsInRound) do
			if count >= 0 then
				sum = sum + count
			end
		end
		return sum
	end)
end

--[[
Computes the number of opponents from each round onward for each section in a
bracket. Lower bracket counts may be negative. This indicates either that an
opponent from the upper bracket dropped down to an earlier round, or that some
opponents leave the tournament directly from the upper bracket.

The third place match is not counted.
]]
---@param bracket MatchGroupUtilBracket
---@return integer[][]
function MatchGroupCoordinates.computeRawCounts(bracket)
	local reverseRounds = Array.reverse(bracket.rounds)

	local countsBySection = Array.map(Array.range(1, #bracket.sections), function(sectionIx) return 0 end)
	local countsByReverseRound = {}
	for _, round in ipairs(reverseRounds) do
		for _, matchId in ipairs(round) do
			local coordinates = bracket.coordinatesByMatchId[matchId]
			local bracketData = bracket.bracketDatasById[matchId]

			local sectionIndex = coordinates.sectionIndex
			local count = 1
			if not bracketData.upperMatchId then
				count = count + 1
				if String.endsWith(matchId, 'RxMTP') then
					count = 0
				end
			elseif coordinates.semanticDepth == 1 then
				-- UB or LB final into grand final
				count = sectionIndex == 1 and 0 or 2
			end
			countsBySection[sectionIndex] = countsBySection[sectionIndex] + count

			-- Loser of match drops down
			if sectionIndex + 1 <= #bracket.sections and coordinates.semanticDepth ~= 0 and not bracketData.qualLose then
				countsBySection[sectionIndex + 1] = countsBySection[sectionIndex + 1] - 1
			end
		end
		table.insert(countsByReverseRound, Table.copy(countsBySection))
	end

	return Array.reverse(countsByReverseRound)
end

return MatchGroupCoordinates
