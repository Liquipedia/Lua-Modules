---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Coordinates
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local IteratorUtil = require('Module:IteratorUtil')
local MathUtil = require('Module:MathUtil')
local StringUtils = require('Module:StringUtils')
local Table = require('Module:Table')
local TreeUtil = require('Module:TreeUtil')

local MatchGroupCoordinates = {}

function MatchGroupCoordinates.dfsFrom(bracketDatasById, start)
	return TreeUtil.dfs(
		function(matchId)
			return bracketDatasById[matchId].lowerMatchIds
		end,
		start
	)
end

function MatchGroupCoordinates.dfs(bracket)
	return IteratorUtil.flatMap(function(_, rootMatchId)
		return MatchGroupCoordinates.dfsFrom(bracket.bracketDatasById, rootMatchId)
	end, ipairs(bracket.rootMatchIds))
end

function MatchGroupCoordinates.computeUpperMatchIds(bracketDatasById)
	local upperMatchIds = {}
	for matchId, bracketData in pairs(bracketDatasById) do
		for _, lowerMatchId in ipairs(bracketData.lowerMatchIds) do
			upperMatchIds[lowerMatchId] = matchId
		end
	end
	return upperMatchIds
end

function MatchGroupCoordinates.computeSections(bracket)
	local sectionIxs = {}
	local sections = {}
	for matchId in MatchGroupCoordinates.dfs(bracket) do
		local bracketData = bracket.bracketDatasById[matchId]
		local upperMatch = bracketData.upperMatchId and bracket.bracketDatasById[bracketData.upperMatchId]
		local isNewSection = bracketData.header ~= nil
			and (not upperMatch or matchId ~= upperMatch.lowerMatchIds[1])
		if isNewSection then
			table.insert(sections, {})
		end
		table.insert(sections[#sections], matchId)
		sectionIxs[matchId] = #sections
	end
	return sections, sectionIxs
end

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
		bracket.rootMatchIds,
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
			local roundIndex = StringUtils.endsWith(matchId, 'RxMTP')
				and #rounds
				or roundProps.depthCount - roundProps.depth

			table.insert(rounds[roundIndex], matchId)
			roundProps.matchIndexInRound = #rounds[roundIndex]
			roundProps.roundIndex = roundIndex
		end
	end

	return rounds, roundPropsByMatchId
end

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

All indexes start from 0. coords.depth is 0-based and coords.semanticDepth is 1-based (0 denotes grand final).

]]
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

return MatchGroupCoordinates
