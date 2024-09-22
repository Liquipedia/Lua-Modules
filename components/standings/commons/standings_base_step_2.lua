---@diagnostic disable: duplicate-set-field, duplicate-doc-field
---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


--- this module (together with /Custom) is basically step 2 in the RFC


local Array = require('Module:Array')
local Box = require('Module:Box')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

---@class storageStanding: standingstable
---@field entries standingsentry[]

local BaseStandings = {}

BaseStandings.Dispaly = Lua.import('Module:Standings/Display') -- todo

---@param args table
---@return Html
function BaseStandings.displayStandingFromLpdb(args)
	assert(args and args.pagename, 'No pagename specified')
	assert(args and Logic.isNumeric(args.standings_index), 'No standings_index specified')

	local conditions = Array.extend(
		args.namespace and ('[[namespace::' .. args.namespace .. ']]') or nil,
		'[[pagename::' .. args.pagename:gsub('%s', '_') .. ']]',
		'[[standingsindex::' .. args.standings_index .. ']]'
	)

	local groups = BaseStandings._query(conditions)

	return BaseStandings._displayGroups(groups)
end

---@param args table
---@return Html
function BaseStandings.displayStageStandingsFromLpdb(args)
	assert(args and args.stage, 'No stage specified')

	local title = mw.title.new(args.stage)
	assert(title, 'Invalid stage specified')

	local namespaceName = Logic.nilIfEmpty(title.nsText)
	local basePageName = title.text
	local stageName = Logic.nilIfEmpty(title.fragment)

	local conditions = Array.extend(
		namespaceName and ('[[namespace::' .. Namespace.idFromName(namespaceName) .. ']]') or nil,
		('[[pagename::' .. basePageName:gsub('%s', '_') .. ']]'),
		stageName and ('[[extradata_stagename::' .. stageName .. ']]') or nil
	)

	local groups = BaseStandings._query(conditions)

	return BaseStandings._displayGroups(groups)
end

---@param conditions string[]
---@return storageStanding[]
function BaseStandings._query(conditions)
	local groups = mw.ext.LiquipediaB.lpdb('standingstable', {
		conditions = table.concat(conditions, ' AND '),
		limit = 5000,
	})

	assert(type(groups[1] == 'table'), 'No results found')

	return Array.map(groups, BaseStandings._fetchEntries)
end

---@param group storageStanding
---@return storageStanding
function BaseStandings._fetchEntries(group)
	local conditions = Array.extend(
		'[[namespace::' .. group.namespace .. ']]',
		'[[pagename::' .. group.pagename .. ']]',
		'[[standingsindex::' .. group.standingsindex .. ']]'
	)

	group.entries = mw.ext.LiquipediaDB.lpdb('standingsentry', {
		conditions = table.concat(conditions, ' AND '),
		limit = '100',
	})

	return group
end

---@param groups storageStanding
---@return Html
function BaseStandings._displayGroups(groups)

	local numberOfGroups = Table.size(groups)

	if numberOfGroups == 1 then
		return BaseStandings.Dispaly(groups[1]):build()
	end

	local display = mw.html.create()
		:node(Box.start{padding = '2em'})

	Array.forEach(groups, function(group, groupIndex)
		display
			:node(BaseStandings.Dispaly(group):build())
			:node(groupIndex ~= numberOfGroups and Box.brk{padding = '2em'} or nil)
	end)

	return display:node(Box.finish())
end

return BaseStandings
