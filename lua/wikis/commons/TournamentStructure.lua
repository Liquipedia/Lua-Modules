---
-- @Liquipedia
-- page=Module:TournamentStructure
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TypeUtil = Lua.import('Module:TypeUtil')

local FULL_PAGENAME = mw.title.getCurrentTitle().prefixedText

local TournamentStructure = {types = {}}

TournamentStructure.types.MatchGroupsSpec = TypeUtil.struct{
	matchGroupIds = TypeUtil.array('string'),
	pageNames = TypeUtil.array(TypeUtil.array('string')),
}

--- Fetches match groups and GroupTableLeague data point records grouped by tournament stage
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return table
function TournamentStructure.fetchStages(spec)
	return TournamentStructure.groupByStage(
		TournamentStructure.fetchGroupTables(spec),
		TournamentStructure.fetchBrackets(spec),
		spec
	)
end

--- Extracts a match group spec from an arguments table. The match group spec is formed using tournamentX=
--- and matchGroupIdX= params, and is used by LPDB fetch functions to know which match groups to fetch.
--- Namespace and tournament stage are suppored for pages names. Namespace is supported for match group IDs.
--- Example of template arguments:
--- |tournament1=PiG Sty Festival
--- |tournament2=StayAtHome Story Cup/4#Group Stage 2
--- |tournament3=User:(16thSq) Kuro/Master Swan Open/64
--- |matchGroupId1=Z1lDMZPiGA
--- |matchGroupId2=Liquipedia_wnbxUh4Vm1
---@param args table
---@return table?
function TournamentStructure.readMatchGroupsSpec(args)
	local matchGroupIds = {args.id}
	table.insert(matchGroupIds, args.matchGroupId)
	for _, id in Table.iter.pairsByPrefix(args, 'matchGroupId') do
		table.insert(matchGroupIds, id)
	end

	local listsOfPageNames = {}
	for _, pageNamesInput in Table.iter.pairsByPrefix(args, 'tournament', {requireIndex = false}) do
		table.insert(listsOfPageNames, Json.parseIfTable(pageNamesInput) or {pageNamesInput})
	end

	local function resolve(rawPageName)
		local namespaceName, basePageName, stageName = TournamentStructure._splitPageName(rawPageName)

		-- args.ns is deprecated
		if not namespaceName and args.ns then
			namespaceName = Namespace.nameFromId(args.ns)
		end

		local pageName = String.isNotEmpty(basePageName)
			and TournamentStructure._createPageName(namespaceName, basePageName)
			or FULL_PAGENAME
		local redirectedPage = mw.title.new(TournamentStructure._resolveRedirect(pageName))
		redirectedPage.fragment = stageName or ''
		assert(redirectedPage, 'Invalid page name "' .. pageName .. '"')
		return redirectedPage.fullText
	end

	if #matchGroupIds ~= 0 or #listsOfPageNames ~= 0 then
		return {
			matchGroupIds = matchGroupIds,
			pageNames = Array.map(listsOfPageNames, function(pageNames)
				return Array.map(pageNames, resolve)
			end),
		}
	else
		return nil
	end
end

---@return {matchGroupIds: {}, pageNames: {[1]: {[1]: string}}}
function TournamentStructure.currentPageSpec()
	return {
		matchGroupIds = {},
		pageNames = {{FULL_PAGENAME}},
	}
end

TournamentStructure._resolveRedirect = FnUtil.memoize(function(pageName)
	return mw.ext.TeamLiquidIntegration.resolve_redirect(pageName)
end)

--- Sorts given group tables and brackets for a given spec into stages
---
--- Limitations:
--- - Stages cannot span multiple tournament pages
--- - The stageName field (as specified by {{Stage|...}})
--- - A stage is contigious within a page
--- - A stage cannot consist of both matchlists and brackets
---
--- Stages are ordered by the match2bracketindex page variable. For stages originating from different pages,
--- the tournamentX arg determines the ordering of pages, hence stage order.
---@param groupTables table
---@param brackets table
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return table
function TournamentStructure.groupByStage(groupTables, brackets, spec)
	local function getStageKey(recordGroup)
		local calculatedStageIndex = recordGroup[1].calculatedStageIndex
		local pageName = table.concat(spec.pageNames[calculatedStageIndex] or {recordGroup[1].pagename})
		return {
			recordGroup[1].stageIndex or -1,
			pageName,
			TournamentStructure.getStageName(recordGroup) or 'default',
			TournamentStructure.isGroupTable(recordGroup) and 'groupTable' or 'bracket'
		}
	end

	local stageIndexes = {}
	Array.forEach(spec.pageNames, function(pageNameArray, stageIndex)
		Array.forEach(pageNameArray, function(page)
			stageIndexes[page] = stageIndex
		end)
	end)

	local getSortKey = FnUtil.memoize(function(recordGroup)
		-- gsub needed to match how pagenames are set up in spec via `TournamentStructure.readMatchGroupsSpec`
		local basePageName = recordGroup[1].pagename:gsub('_', ' ')
		local stageName = TournamentStructure.getStageName(recordGroup)
		local namespaceName = String.nilIfEmpty(Namespace.nameFromId(recordGroup[1].namespace))
		local pageName = TournamentStructure._createPageName(namespaceName, basePageName, stageName)
		local wholePageName = TournamentStructure._createPageName(namespaceName, basePageName)

		local stageIndex = recordGroup[1].stageIndex or stageIndexes[pageName] or stageIndexes[wholePageName]
		-- need it available for later
		recordGroup[1].calculatedStageIndex = stageIndex

		return TournamentStructure.isGroupTable(recordGroup)
			and {
				stageIndex or -1,
				recordGroup[1].extradata.bracketIndex or -1,
				0,
				0,
				tonumber(recordGroup[1].standingsindex) or -1,
			}
			or {
				stageIndex or -1,
				tonumber((recordGroup[1].match2bracketdata or {}).bracketindex) or -1,
				Array.indexOf(spec.pageNames[stageIndex] or {}, function(page)
					return page == wholePageName or page == pageName
				end),
				1,
				0,
			}
	end)

	local recordGroups = Array.extend(groupTables, brackets)
	recordGroups = Array.filter(recordGroups, function(recordGroup) return Table.isNotEmpty(recordGroup) end)

	Array.sortInPlaceBy(recordGroups, getSortKey)
	return Array.groupAdjacentBy(recordGroups, getStageKey)
end

--- Checks if a given data set "recordGroup" is a group table (standings table) or not
---@param recordGroup table
---@return boolean
function TournamentStructure.isGroupTable(recordGroup)
	return recordGroup[1].standingsindex ~= nil
end

--- Retrieves the stage name from a data set (either bracket or standings table)
---@param recordGroup table
---@return string?
function TournamentStructure.getStageName(recordGroup)
	return TournamentStructure.isGroupTable(recordGroup)
		and recordGroup[1].extradata.stageName
		or String.nilIfEmpty((recordGroup[1].match2bracketdata or {}).sectionheader)
end

--- Builds a filter (condition string) for a given matchGroupId
---@param matchGroupId string
---@return string
function TournamentStructure.getMatchGroupFilter(matchGroupId)
	local namespaceName = matchGroupId:match('^(%w+)_')
	local clauses = Array.extend(
		namespaceName and ('[[namespace::' .. Namespace.idFromName(namespaceName) .. ']]') or nil,
		'[[match2bracketid::' .. matchGroupId .. ']]'
	)
	return table.concat(clauses, ' AND ')
end

--- Builds a filter (condition string) for a given matchGroupType and pageName
---@param matchGroupType string
---@param pageNames string[]
---@return string
function TournamentStructure.getPageNamesFilter(matchGroupType, pageNames)
	local pageClauses = Array.map(pageNames, FnUtil.curry(TournamentStructure.getPageNameFilter, matchGroupType))
	return '(' .. table.concat(pageClauses, ' OR ') .. ')'
end

--- Builds a filter (condition string) for a given matchGroupType and pageName
---@param matchGroupType string
---@param pageName string
---@return string
function TournamentStructure.getPageNameFilter(matchGroupType, pageName)
	local namespaceName, basePageName, stageName = TournamentStructure._splitPageName(pageName)
	local clauses = Array.extend(
		namespaceName and ('[[namespace::' .. Namespace.idFromName(namespaceName) .. ']]') or nil,
		('[[pagename::' .. basePageName:gsub('%s', '_') .. ']]'),
		stageName and (matchGroupType == 'bracket') and ('[[match2bracketdata_sectionheader::' .. stageName .. ']]') or nil,
		stageName and (matchGroupType == 'standingstable') and ('[[extradata_stagename::' .. stageName .. ']]') or nil
	)
	return table.concat(clauses, ' AND ')
end

--- Fetches brackets (matches) for a given filter (condition string).
---@param filter string
---@return table
function TournamentStructure.fetchBracketsFromFilter(filter)
	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
			conditions = filter .. ' AND [[match2bracketdata_type::bracket]]',
			limit = 5000,
		})

	---@param match match2
	---@return boolean
	local isFfaMatch = function(match)
		return #(match.match2opponents or {}) > 2
	end

	-- exclude FFA/BR Brackets, due to them causing issues
	if Array.any(matches, isFfaMatch) then
		return {}
	end

	return matches
end

--- Fetches groups (standings tables) for a given filter (condition string).
---@param filter string
---@return table
function TournamentStructure.fetchGroupsFromFilter(filter)
	return mw.ext.LiquipediaDB.lpdb('standingstable', {
			query = 'namespace, pagename, standingsindex, title, extradata, matches, type, config',
			conditions = filter,
			limit = 5000,
		})
end

--- Fetch group table results from standings table.
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return table
function TournamentStructure.fetchGroupTables(spec)
	local pageData = Array.flatten(Array.map(spec.pageNames, function(pageName, groupIndex)
				return Array.map(
					TournamentStructure.fetchGroupsFromFilter(TournamentStructure.getPageNamesFilter('standingstable', pageName)),
					function(standingsGroup)
						standingsGroup.stageIndex = groupIndex
						return standingsGroup
					end)
			end))

	local groups = Array.filter(pageData, Table.isNotEmpty)

	groups = Array.map(groups, TournamentStructure.fetchGroupTableEntries)

	return groups
end

--- Fetches standings entries belonging to a given group (standings table)
---@param group table
---@return table
function TournamentStructure.fetchGroupTableEntries(group)
	local groupExtradata = group.extradata or {}
	local roundIndex = groupExtradata.roundcount
	if not roundIndex then
		return {}
	end

	local records = mw.ext.LiquipediaDB.lpdb('standingsentry', {
		conditions = '[[standingsindex::' .. group.standingsindex .. ']] AND '
			.. '[[pagename::' .. group.pagename .. ']] AND [[roundindex::' .. roundIndex .. ']]',
		limit = 1000,
		query = 'scoreboard, currentstatus, extradata, opponenttype, '
			.. 'opponentname, opponenttemplate, opponentplayers, placement'
	})

	local sortFunction = function(record1, record2)
		local value1 = tonumber(record1.extradata.slotindex) or tonumber(record1.placement) or -1
		local value2 = tonumber(record2.extradata.slotindex) or tonumber(record2.placement) or -1

		return value1 < value2 or value1 == value2 and record1.opponentname < record2.opponentname
	end

	table.sort(records, sortFunction)

	local placeMapping = groupExtradata.placemapping
	if placeMapping then
		for _, record in pairs(records) do
			local sortValue = tonumber(record.extradata.slotindex) or tonumber(record.placement)
			sortValue = placeMapping[sortValue] or sortValue
			record.extradata.slotindex = sortValue
			record.placement = tostring(sortValue)
		end
	end

	return TournamentStructure._mergeGroupEntriesIntoGroup(records, group)
end

--- Merges groupEntries into a group
---@param entries table
---@param group table
---@return table
function TournamentStructure._mergeGroupEntriesIntoGroup(entries, group)
	local transformedGroup = {}
	for _, entry in ipairs(entries) do
		local opponent = Lua.import('Module:OpponentLibraries').Opponent.fromLpdbStruct(entry)
		local finished = group.extradata.finished or group.extradata.groupfinished
		local extradata = {
			placeRange = entry.extradata.placerange,
			placeRangeIsExact = entry.extradata.placerangeisexact,
			showMatchDraws = (group.config or {}).hasdraws or group.extradata.hasdraw,
			stageName = group.extradata.stagename,
			slotIndex = tonumber(entry.extradata.slotindex),
			groupFinished = finished,
			finished = finished,
			enddate = group.extradata.enddate or group.extradata.endtime,
			endTime = group.extradata.enddate or group.extradata.endtime,
			bracketIndex = group.extradata.bracketindex,
		}

		table.insert(transformedGroup, Table.merge(group, {
					opponent = opponent,
					extradata = extradata,
					scoreboard = entry.scoreboard,
					currentstatus = entry.currentstatus,
					matches = group.matches,
					placement = TournamentStructure._groupPlacement(finished, entry.extradata.slotindex, entry.placement),
					type = group.type,
					hasDraw = group.extradata.hasdraw,
					hasOvertime = group.extradata.hasovertime,
				}))
	end

	return transformedGroup
end

--- Determines the group placement to be used in further processing depending if the group is finished or not
---@param finished boolean?
---@param slotIndex string|number|nil
---@param placement string|number|nil
---@return number?
function TournamentStructure._groupPlacement(finished, slotIndex, placement)
	if finished then
		return tonumber(placement) or tonumber(slotIndex)
	end

	return tonumber(slotIndex) or tonumber(placement)
end

--- Converts a match group spec to a standing record filter. Returns a filter string for use in LPDB queries.
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return string
function TournamentStructure.getGroupTableFilter(spec)
	local whereClauses = Array.map(spec.pageNames, function(pageName)
			return TournamentStructure.getPageNamesFilter('standingstable', pageName)
		end)

	return '(' .. table.concat(whereClauses, ' OR ') .. ')'
end

--- Fetches bracket data (matches) for a given match group spec.
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return table
function TournamentStructure.fetchBrackets(spec)
	local idData = Array.map(spec.matchGroupIds, function(matchGroupId)
			return TournamentStructure.fetchBracketsFromFilter(TournamentStructure.getMatchGroupFilter(matchGroupId))
		end)

	local pageData = Array.flatten(Array.map(spec.pageNames, function(pageName, stageIndex)
				local groupedData = Array.groupBy(Array.map(
						TournamentStructure.fetchBracketsFromFilter(TournamentStructure.getPageNamesFilter('bracket', pageName)),
						function(bracketMatch)
							bracketMatch.stageIndex = stageIndex
							return bracketMatch
						end), function(record) return record.match2bracketid end)
				return groupedData
			end))

	return Array.extend(idData, pageData)
end

--- Converts a match group spec to a match2 record filter. Returns a filter string for use in LPDB queries.
---@param spec {matchGroupIds: table, pageNames: string[][]}
---@return string
function TournamentStructure.getMatch2Filter(spec)
	local whereClauses = Array.extend(
		Array.map(spec.matchGroupIds, TournamentStructure.getMatchGroupFilter),
		Array.map(spec.pageNames, function(pageName)
				return TournamentStructure.getPageNamesFilter('bracket', pageName)
			end)
	)
	return '(' .. table.concat(whereClauses, ' OR ') .. ')'
end

--- Splits a page name into a namespace, base, and stage.
---@param pageName string
---@return string?, string, string?
function TournamentStructure._splitPageName(pageName)
	local title = mw.title.new(pageName)
	assert(title, 'Invalid pagename "' .. pageName .. '"')
	return String.nilIfEmpty(title.nsText), title.text, String.nilIfEmpty(title.fragment)
end

--- Joins given namespace, base page name, and stage into a page name.
---@param namespaceName string?
---@param basePageName string
---@param stageName string?
---@return string
function TournamentStructure._createPageName(namespaceName, basePageName, stageName)
	if String.isEmpty(basePageName) then
		return ''
	end
	return mw.title.makeTitle(namespaceName or '', basePageName, stageName).fullText
end

return TournamentStructure
