---

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local HighlightConditions = require('Module:HighlightConditions')
local LeagueIcon = require('Module:LeagueIcon')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Logic = require('Module:Logic')
local Tier = require('Module:Tier/Custom')

local CURATED_DATA = Lua.requireIfExists('Module:TournamentsList/CuratedData', {loadData = true})

local TournamentsList = {}
local helperFunctions = {}

local COLOR_CLASSES = {
	['1'] = 'tier1',
	['2'] = 'tier2',
	['3'] = 'tier3',
	['4'] = 'tier4',
	['5'] = 'tier5',
	['Qualifier'] = 'qualifier',
	['Monthly'] = 'monthly',
	['Weekly'] = 'weekly',
	['Showmatch'] = 'showmatch',
	['Misc'] = 'misc',
	['-1'] = 'misc',
	['School'] = 'misc',
	['default'] = 'misc', -- When no match on any other tier
}

local DEFAULT_TIER = -1

function TournamentsList.run(args)
	return  mw.html.create('div'):node(TournamentsList._initializeLists(args))
end


function TournamentsList._initializeLists(args)
	local filterCategories = {
		'liquipediatier',
		Logic.readBool(args.filterByTierTypes) and 'liquipediatiertype' or nil,
	}

	local upcomingDays = tonumber(args['upcomingDays'] or 5)
	local completedDays = tonumber(args['completedDays'] or 5)

	local tournaments = helperFunctions.fetchTournaments(upcomingDays, completedDays)
	local fallback = mw.html.create('div')
			   :attr('data-filter-hideable-group-fallback', '')
			   :node(mw.html.create('hr'))
			   :node(mw.html.create('center'):css('margin', '1.5rem 0'):tag('i'):wikitext('No tournaments found for your selected filters!'):allDone())
	local list = mw.html.create('ul')
				   :addClass('tournaments-list')
				   :attr('data-filter-hideable-group', '')
				   :attr('data-filter-effect', 'fade')
				   :node(helperFunctions.createSubList('Upcoming', tournaments.upcoming, filterCategories))
				   :node(helperFunctions.createSubList('Ongoing', tournaments.ongoing, filterCategories))
				   :node(helperFunctions.createSubList('Concluded', tournaments.completed, filterCategories))
				   :node(fallback)

	return list, tournaments
end

function helperFunctions.buildConditions(upcomingDays, completedDays)
	local currentTime = os.time()

	local conditions = '[[status::]] AND [[liquipediatiertype::!Points]]'

	local qualifierCompletedOffset = os.date('!%Y-%m-%d', currentTime - 86400 * (completedDays - 2))
	local qualifierConditions = {
		'[[liquipediatiertype::!Qualifier]]',
		'[[sortdate::>' .. qualifierCompletedOffset .. ']]',
	}
	conditions = conditions .. ' AND (' .. table.concat(qualifierConditions, ' OR ') .. ')'

	local defaultUpcomingThreshold = os.date('!%Y-%m-%d', currentTime + 86400 * upcomingDays)
	local tier3UpcomingThreshold = os.date('!%Y-%m-%d', currentTime + 86400 * (upcomingDays + 10))
	local tier2UpcomingThreshold = os.date('!%Y-%m-%d', currentTime + 86400 * (upcomingDays + 55))

	local startConditions = {
		'[[startdate::<' .. defaultUpcomingThreshold .. ']]',
		'[[startdate::<' .. tier3UpcomingThreshold .. ']] AND [[liquipediatier::<4]]',
		'[[startdate::<' .. tier2UpcomingThreshold .. ']] AND [[liquipediatier::<3]]',
	}
	conditions = conditions .. ' AND (' .. table.concat(startConditions, ' OR ') .. ') AND [[startdate::!' .. DateExt.defaultDate .. ']]'

	local defaultCompletedThreshold = os.date('!%Y-%m-%d', currentTime - 86400 * completedDays)
	local tier3CompletedThreshold = os.date('!%Y-%m-%d', currentTime - 86400 * (completedDays + 10))
	local tier2CompletedThreshold = os.date('!%Y-%m-%d', currentTime - 86400 * (completedDays + 55))

	local endConditions = {
		'[[sortdate::>' .. defaultCompletedThreshold .. ']]',
		'[[sortdate::>' .. tier3CompletedThreshold .. ']] AND [[liquipediatier::<4]]',
		'[[sortdate::>' .. tier2CompletedThreshold .. ']] AND [[liquipediatier::<3]]',
		'[[sortdate::' .. DateExt.defaultDate .. ']] AND [[liquipediatier::1]]',
	}
	return conditions .. ' AND (' .. table.concat(endConditions, ' OR ') .. ')'
end

function helperFunctions.fetchTournaments(upcomingDays, completedDays)
	local today = os.date('!%Y-%m-%d')
	local conditions = helperFunctions.buildConditions(upcomingDays, completedDays)
	local tournaments = mw.ext.LiquipediaDB.lpdb(
			'tournament',
			{
				limit = 250,
				order = 'sortdate desc, startdate desc, tickername asc, pagename asc',
				conditions = conditions,
			}
	)

	local upcoming, ongoing, completed = {}, {}, {}

	for _, event in ipairs(tournaments) do
		event.tickername = Logic.emptyOr(
			event.tickername,
			event.name
		) or event.pagename:gsub('_', ' ')
		if event.startdate > today then
			table.insert(upcoming, event)
		elseif event.sortdate ~= DateExt.defaultDate and event.sortdate < today or event.status == 'finished' then
			table.insert(completed, event)
		else
			table.insert(ongoing, event)
		end
	end

	table.sort(upcoming, function(a, b)
		if a.startdate == b.startdate then
			return a.sortdate > b.sortdate
		else
			return a.startdate > b.startdate
		end
	end)

	return {
		upcoming = upcoming,
		ongoing = ongoing,
		completed = completed
	}
end

function helperFunctions.createSubList(name, tournaments, filterCategories)
	if Table.isEmpty(tournaments) then
		return
	end

	local header = mw.html.create('span')
					 :addClass('tournaments-list-heading')
					 :wikitext(name)

	local list = mw.html.create('ul')
				   :addClass('tournaments-list-type-list')

	local listGroup = mw.html.create('div')
				   :node(list)

	for index, tournament in ipairs(tournaments) do
		list:node(helperFunctions.buildTournamentNode(tournament, filterCategories))
	end

	return mw.html.create('li')
			 :attr('data-filter-hideable-group', '')
			 :attr('data-filter-effect', 'fade')
			 :node(header)
			 :node(listGroup)
end

function helperFunctions.buildTournamentNode(tournament, filterCategories)
	if String.isEmpty(tournament.icon) and String.isEmpty(tournament.icondark) then
		tournament.icon = 'Generic Tournament icon.png'
	end
	local icon = LeagueIcon.display(Table.merge(tournament, { link = tournament.pagename, iconDark = tournament.icondark }))
	local curated = CURATED_DATA ~= nil and helperFunctions.determineIfFeatured(CURATED_DATA, tournament)

	local wrap = mw.html.create('div')
				   :cssText('display:flex; gap: 5px; margin-top:0.3em; margin-left:10px')
				   :node(helperFunctions.getTierLabels(tournament))
				   :node(mw.html.create('span')
						   :addClass('tournaments-list-name')
						   :cssText('flex-grow:1; padding-left: 25px;')

						   :node(icon)
						   :wikitext('[[' .. tournament.pagename .. '|' .. tournament.tickername .. ']]')
	)
				   :node(mw.html.create('small')
						   :addClass('tournaments-list-dates')
						   :cssText('flex-shrink:0;')
						   :wikitext(helperFunctions.getDateString(tournament))
	)

	for _, groupName in pairs(filterCategories) do
		local category = tournament[groupName]
		local filterGroup = 'filterbuttons-' .. groupName

		wrap = mw.html.create('div')
				 :node(wrap)
				 :attr('data-filter-group', filterGroup)
				 :attr('data-filter-category', category)
		if curated then
			wrap:attr('data-curated', '')
		end
	end

	return mw.html.create('li'):node(wrap)
end

function helperFunctions.determineIfFeatured(curated, tournament)
	if Table.includes(curated.exclude, tournament.pagename) then
		return false
	end
	local tierIdentifier = Tier.toIdentifier(tournament.liquipediatier)
	if tierIdentifier == 1 or tierIdentifier == 2 or HighlightConditions.tournament(tournament) then
		table.insert(curated.include, tournament.pagename)
		return true
	else
		local inCuratedTable = Table.any(curated.include, function(_, curatedItem)
			if String.isNotEmpty(tournament.liquipediatiertype) then
				local parentInTable = tonumber((tournament.pagename:find(curatedItem)))
				if parentInTable then table.insert(curated.include, tournament.pagename) end
				return parentInTable ~= nil
			else
				return tournament.pagename == curatedItem
			end
		end)
		if inCuratedTable then return true end
		if String.isNotEmpty(tournament.liquipediatiertype) then
			helperFunctions.dontQueryParents = helperFunctions.dontQueryParents or {}
			local parentTournament = helperFunctions.getParentTournamentData(tournament.pagename)
			if parentTournament then
				local parentCurated = helperFunctions.determineIfFeatured(curated, parentTournament)
				if parentCurated then
					table.insert(curated.include, tournament.pagename)
				else
					helperFunctions.dontQueryParents[parentTournament.pagename] = true
				end
				return parentCurated
			end
		end
	end
	return false
end

function helperFunctions.getParentTournamentData(pagename)
	local parentPagenameArray = Array.sub(mw.text.split(pagename, '/'), 1, -2)
	if Table.isEmpty(parentPagenameArray) then return end
	local parentPagename = table.concat(parentPagenameArray, '/')
	if helperFunctions.dontQueryParents[parentPagename] then return end
	local parentTournament = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. parentPagename .. ']]',
		query = 'pagename, liquipediatier',
		limit = 1,
	})
	if not parentTournament[1] then
		local parentData = helperFunctions.getParentTournamentData(parentPagename)
		if not parentData then
			helperFunctions.dontQueryParents[parentPagename] = true
		end
		return parentData
	end
	return parentTournament[1]
end

function helperFunctions.getTierLabels(tournament)
	local liquipediatier, liquipediatiertype = Tier.parseFromQueryData(tournament)
	if String.isEmpty(liquipediatier) then
		liquipediatier = DEFAULT_TIER
	end

	local tier = Tier.toName(liquipediatier)
	local tierShort, tierTypeShort = Tier.toShortName(liquipediatier, liquipediatiertype)

	local tierNode, tierTypeNode = mw.html.create('div')
	if String.isNotEmpty(tierTypeShort) then
		tierNode
				:addClass('tournament-badge__chip')
				:addClass('chip--' .. COLOR_CLASSES[liquipediatier])
				:wikitext(tierShort) -- TODO: Remove later (adds tiertype)
		tierTypeNode = mw.html.create('div')
						 :addClass('tournament-badge__text')
						 :wikitext(tierTypeShort)
	else
		tierNode
				:addClass('tournament-badge__text')
				:wikitext(tier)
	end

	return mw.html.create('div')
		:addClass('tournament-badge')
		:addClass('badge--' .. Logic.emptyOr(
			String.isNotEmpty(liquipediatiertype)
				and (COLOR_CLASSES[liquipediatiertype or ''] or COLOR_CLASSES['default'])
				or nil,
			COLOR_CLASSES[liquipediatier or ''],
			COLOR_CLASSES['default']
		))
		:node(tierNode)
		:node(tierTypeNode)
end

function helperFunctions.getDateString(tournament)
	local startdateParsed = DateExt.parseIsoDate(tournament.startdate)
	local enddateParsed = DateExt.parseIsoDate(tournament.sortdate)
	local startString = startdateParsed and os.date('%b %d', startdateParsed) or 'TBD'
	local endString = enddateParsed and os.date('%b %d', enddateParsed) or 'TBD'

	if startString == endString then
		endString = ''
	elseif endString ~= 'TBD' and os.date('%m', startdateParsed) == os.date('%m', enddateParsed) then
		endString = os.date('%d', enddateParsed)
	end
	local dateString = startString .. (endString ~= '' and ' - ' .. endString or '')

	return '[[' .. tournament.pagename .. '|' .. dateString .. ']]'
end

return Class.export(TournamentsList)
