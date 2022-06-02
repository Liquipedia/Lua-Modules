---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local League = require('Module:Infobox/League')
local Namespace = require('Module:Namespace')
local PageLink = require('Module:Page')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local Breakdown = require('Module:Infobox/Widget/Breakdown')
local Chronology = require('Module:Infobox/Widget/Chronology')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _next
local _previous

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.shouldStore = CustomLeague.shouldStore

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'chronology' then
		local content = CustomLeague._getChronologyData()
		if String.isNotEmpty(content.previous) or String.isNotEmpty(content.next) then
			return {
				Title{name = 'Chronology'},
				Chronology{
					content = content
				}
			}
		end
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{name = 'Patch', content = {CustomLeague._getPatch()}})
	elseif id == 'customcontent' then
		--player breakdown
		local playerRaceBreakDown = CustomLeague._playerRaceBreakDown() or {}
		--make playerNumber available for commons category check
		_args.player_number = playerRaceBreakDown.playerNumber
		local playerNumber = _args.player_number or 0
		Variables.varDefine('tournament_playerNumber', playerNumber)
		if playerNumber > 0 then
			table.insert(widgets, Title{name = 'Player breakdown'})
			table.insert(widgets, Cell{name = 'Number of players', content = {playerNumber}})
			table.insert(widgets, Breakdown{content = playerRaceBreakDown.display, classes = {'infobox-center'}})
		end

		--teams section
		if _args.team_number or String.isNotEmpty(_args.team1) then
			Variables.varDefine('is_team_tournament', 1)
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		if String.isNotEmpty(_args.team1) then
			local teams = CustomLeague:_makeBasedListFromArgs('team')
			table.insert(widgets, Center{content = teams})
		end

		--maps
		if String.isNotEmpty(_args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('map')})
		elseif String.isNotEmpty(_args['2map1']) then
			table.insert(widgets, Title{name = _args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('2map')})
		elseif String.isNotEmpty(_args['3map1']) then
			table.insert(widgets, Title{name = _args['3maptitle'] or '3v3 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('3map')})
		end
	end
	return widgets
end

function CustomLeague._getPatch()
	local patch = _args.patch
	local endPatch = _args.epatch
	if String.isEmpty(patch) then
		return nil
	end

	Variables.varDefine('patch', patch)
	Variables.varDefine('epatch', String.isNotEmpty(endPatch) and endPatch or patch)

	if String.isEmpty(endPatch) then
		return '[[' .. patch .. ']]'
	else
		return '[[' .. patch .. ']] &ndash; [[' .. endPatch .. ']]'
	end
end

function CustomLeague._getChronologyData()
	_next, _previous = CustomLeague._computeChronology()
	return {
		previous = _previous,
		next = _next,
		previous2 = _args.previous2,
		next2 = _args.next2,
		previous3 = _args.previous3,
		next3 = _args.next3,
	}
end

-- Automatically fill in next/previous for touranaments that are part of a series
function CustomLeague._computeChronology()
	-- Criteria for automatic chronology are
	-- - part of a series and numbered
	-- - the subpage name matches the number
	-- - prev or next are unspecified
	-- - and not suppressed via auto_chronology=false
	local title = mw.title.getCurrentTitle()
	local number = tonumber(title.subpageText or '')
	local automateChronology =
		(_args.series or '') ~= ''
		and number ~= nil
		and tonumber(_args.number or '') == number
		and title.subpageText ~= title.text
		and _args.auto_chronology ~= 'false'
		and ((_args.next or '') == '' or (_args.previous or '') == '')

	if automateChronology then
		local previous = (_args.previous or '') ~= '' and _args.previous
		local next = (_args.next or '') ~= '' and _args.next
		local nextPage = (_args.next or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number + 1)).fullText
		local previousPage = (_args.previous or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number - 1)).fullText

		if not next and PageLink.exists(nextPage) then
			next = nextPage .. '|#' .. tostring(number + 1)
		end

		if not previous and 1 < number and PageLink.exists(previousPage) then
			previous = previousPage .. '|#' .. tostring(number - 1)
		end

		return next or nil, previous or nil
	else
		return _args.next, _args.previous
	end
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		Variables.varDefault('disable_SMW_storage', 'false') ~= 'true' and
		Variables.varDefault('disable_LPDB_storage', 'false') ~= 'true'
end

function CustomLeague._playerRaceBreakDown()
	local playerBreakDown = {}
	local playerNumber = tonumber(_args.player_number or 0) or 0
	local zergNumber = tonumber(_args.zerg_number or 0) or 0
	local terranNumbner = tonumber(_args.terran_number or 0) or 0
	local protossNumber = tonumber(_args.protoss_number or 0) or 0
	local randomNumber = tonumber(_args.random_number or 0) or 0
	if playerNumber == 0 then
		playerNumber = zergNumber + terranNumbner + protossNumber + randomNumber
	end

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		if zergNumber + terranNumbner + protossNumber + randomNumber > 0 then
			playerBreakDown.display = {}
			if protossNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'p'})
					.. ' ' .. protossNumber)
			end
			if terranNumbner > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'t'})
					.. ' ' .. terranNumbner)
			end
			if zergNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'z'})
					.. ' ' .. zergNumber)
			end
			if randomNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'r'})
					.. ' ' .. randomNumber)
			end
		end
	end
	Variables.varDefine('nbnotableP', protossNumber)
	Variables.varDefine('nbnotableT', terranNumbner)
	Variables.varDefine('nbnotableZ', zergNumber)
	Variables.varDefine('nbnotableR', randomNumber)
	return playerBreakDown or {}
end

function CustomLeague:_makeBasedListFromArgs(prefix)
	local foundArgs = {}
	for key, linkValue in Table.iter.pairsByPrefix(_args, prefix) do
		local displayValue = String.isNotEmpty(_args[key .. 'display'])
			and _args[key .. 'display']
			or linkValue

		table.insert(
			foundArgs,
			tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, displayValue, linkValue)
			))
		)
	end

	return {table.concat(foundArgs, '&nbsp;• ')}
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_abbreviation', _args.abbreviation or '')
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))

	--Legacy date vars
	local startDate = Variables.varDefault('tournament_startdate', '')
	local endDate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('date', endDate)
	Variables.varDefine('sdate', startDate)
	Variables.varDefine('edate', endDate)
	Variables.varDefine('formatted_tournament_date', startDate)
	Variables.varDefine('formatted_tournament_edate', endDate)
	Variables.varDefine('prizepooldate', endDate)
	Variables.varDefine('lpdbtime', mw.getContentLanguage():formatDate('U', endDate))

	--SC specific vars
	Variables.varDefine('tournament_mode', _args.mode or '1v1')
	Variables.varDefine('headtohead', _args.headtohead or 'true')
	--series number
	local seriesNumber = _args.number or ''
	local seriesNumberLength = string.len(seriesNumber)
	if seriesNumberLength > 0 then
		seriesNumber = string.rep('0', 5 - seriesNumberLength) .. seriesNumber
	end
	Variables.varDefine('tournament_series_number', seriesNumber)
	--check if tournament is finished
	local finished = _args.finished
	local queryDate = Variables.varDefault('tournament_enddate', '2999-99-99')
	if finished ~= 'true' and os.date('%Y-%m-%d') >= queryDate then
		local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
				.. 'AND [[participant::!Definitions]] AND [[placement::1]]',
			query = 'date',
			order = 'date asc',
			limit = 1
		})
		if data ~= nil and data[1] ~= nil then
			finished = 'true'
		end
	end
	Variables.varDefine('tournament_finished', finished or 'false')
end

function CustomLeague:addToLpdb(lpdbData)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.patch = Variables.varDefault('patch', '')
	lpdbData.endpatch = Variables.varDefault('epatch', '')
	local status = _args.status
		or Variables.varDefault('cancelled tournament', '') == 'true' and 'cancelled'
		or Variables.varDefault('tournament_finished', '') == 'true' and 'finished'
	lpdbData.status = status
	lpdbData.maps = CustomLeague:_concatArgs('map')
	lpdbData.participantsnumber = Variables.varDefault('tournament_playerNumber', _args.team_number or 0)
	lpdbData.next = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_next))
	lpdbData.previous = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_previous))

	return lpdbData
end

function CustomLeague:_concatArgs(base)
	local firstArg = _args[base] or _args[base .. '1']
	if String.isEmpty(firstArg) then
		return nil
	end
	local foundArgs = {mw.ext.TeamLiquidIntegration.resolve_redirect(firstArg)}
	local index = 2
	while String.isNotEmpty(_args[base .. index]) do
		table.insert(foundArgs,
			mw.ext.TeamLiquidIntegration.resolve_redirect(_args[base .. index])
		)
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague:_getPageNameFromChronology(item)
	if String.isEmpty(item) then
		return ''
	end

	return mw.text.split(item, '|')[1]
end

return CustomLeague
