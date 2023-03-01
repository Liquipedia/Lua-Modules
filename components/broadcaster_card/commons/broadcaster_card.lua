---
-- @Liquipedia
-- wiki=commons
-- page=Module:BroadcasterCard
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Weight = Lua.requireIfExists('Module:BroadCasterWeight')

local TBD = 'TBD'

local BroadcasterCard = {}

function BroadcasterCard.create(frame)
	local args = Arguments.getArgs(frame)
	local language = args.lang
	local restrictedQuery = Logic.readBool(args.restrictedQuery)

	-- Get position & title from various input variants
	local position, title

	if args.position then
		position = args.position
	elseif Variables.varDefault('position') then
		position = Variables.varDefault('position')
	elseif args.b1 then
		position = 'Commentator'
	else
		position = TBD
	end

	if args.title then
		title = args.title
	elseif position == TBD then
		title = Abbreviation.make(TBD, 'To Be Determined')
	else
		-- Create a title from the position.
		local positions = Array.map(
			mw.text.split(position, '/'),
			function(pos) return mw.text.trim(pos) end
		)
		if args.b2 then
			positions = Array.map(positions, BroadcasterCard._pluralisePosition)
		end
		title = table.concat(positions, '/')  .. ':'
	end

	-- Html for header
	local outputList = tostring(mw.html.create():wikitext('*'):tag('b'):wikitext(title):allDone())

	-- Refence
	if String.isNotEmpty(args.ref) then
		outputList = outputList .. ' ' .. frame:callParserFunction{name = '#tag', args = {'ref', args.ref}}
	end

	-- Add people
	local casters = {}
	for prefix, caster, casterIndex in Table.iter.pairsByPrefix(args, 'b') do
		local link = args[prefix .. 'link'] or caster
		local name, nationality = BroadcasterCard.getData(args, prefix, link, restrictedQuery)
		local date = Variables.varDefault('tournament_enddate')

		local broadcaster = {
			id = caster,
			name = name or '',
			displayName = args[prefix .. 'name_o'],
			page = mw.ext.TeamLiquidIntegration.resolve_redirect(link):gsub(' ','_' ),
			language = language,
			position = position,
			weight = BroadcasterCard.getWeight(),
			flag = (nationality or ''):lower(),
			date = date,
			sort = tonumber(args[prefix .. 'sort'])
		}
		broadcaster.sort = BroadcasterCard.sortValue(broadcaster, args.sort, casterIndex)

		BroadcasterCard.setLPDB(broadcaster, args.status)

		table.insert(casters, broadcaster)
	end

	if Table.isEmpty(casters) then
		return outputList .. '\n**' .. Abbreviation.make('TBA', 'To Be Announced')
	end

	table.sort(casters, function(a, b) return a.sort < b.sort or (a.sort == b.sort and a.id < b.id) end)

	for _, broadcaster in ipairs(casters) do
		outputList = outputList .. BroadcasterCard._display(broadcaster)
	end

	return outputList
end

function BroadcasterCard._display(broadcaster)
	local displayName = broadcaster.displayName or broadcaster.name
	displayName = String.isEmpty(displayName) and '' or ('&nbsp;(' .. displayName ..')')

	return '\n**' .. Flags.Icon{flag = broadcaster.flag, shouldLink = true}
		.. '&nbsp;[[' .. broadcaster.page .. '|'.. broadcaster.id .. ']]'
		.. displayName
end

function BroadcasterCard._pluralisePosition(position)
	return String.endsWith(position, 's') and position or (position .. 's')
end

function BroadcasterCard.getData(args, prefix, casterPage, restrictedQuery)
	local resolvedCasterPage = mw.ext.TeamLiquidIntegration.resolve_redirect(casterPage):gsub(' ','_' )

	local function getPersonInfo()
		local data = mw.ext.LiquipediaDB.lpdb('player', {
			conditions = '[[pagename::' .. resolvedCasterPage .. ']]',
			query = 'romanizedname, name, pagename, nationality',
			limit = 1,
		})

		if type(data) == 'table' and data[1] then
			return String.nilIfEmpty(data[1].romanizedname) or data[1].name, data[1].nationality
		end

		if String.isNotEmpty(args[prefix .. 'name']) and String.isNotEmpty(args[prefix .. 'flag' ]) or restrictedQuery then
			return args[prefix .. 'name' ],	args[prefix .. 'flag' ]
		end

		data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
			conditions = '[[page::' .. resolvedCasterPage .. ']] AND [[name::!]] AND [[flag::!]]',
			query = 'name, flag, id',
			order = 'date desc',
			limit = 1
		})
		if type(data) == 'table' and data[1] then
			return data[1].name, data[1].flag
		end

		return args[prefix .. 'name'], args[prefix .. 'flag']
	end

	return getPersonInfo()
end

function BroadcasterCard.sortValue(broadcaster, sortMode, casterIndex)
	if sortMode == 'flag' then
		return broadcaster.flag
	elseif sortMode == 'manual' then
		return 99 - (broadcaster.sort or 0)
	end

	return casterIndex
end

function BroadcasterCard.setLPDB(caster, status)
	local smName = Variables.varDefault('show_match_name') or ''
	local extradata = {status = ''}
	if Logic.readBool(Variables.varDefault('show_match')) then
		extradata.showmatchname = smName
		extradata.showmatch = 'true'
	end
	if Variables.varDefault('tournament_status') then
		extradata.status = status ~= 'save' and Variables.varDefault('tournament_status') or ''
	end

	extradata.liquipediatier = Variables.varDefaultMulti('tournament_liquipediatier', '')
	extradata.liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype')
	extradata.publishertier = Variables.varDefault('tournament_publishertier')
	extradata.game = Variables.varDefault('tournament_game')

	mw.ext.LiquipediaDB.lpdb_broadcasters(
		'broadcaster_' .. caster.id .. '_' .. caster.position:gsub(' ','_') .. smName:gsub(' ','_'),
		{
			id = caster.id,
			name = caster.name,
			page = caster.page,
			language = caster.language or '',
			flag = caster.flag,
			position = caster.position,
			weight = caster.weight,
			date = caster.date,
			parent = Variables.varDefault('tournament_parent'),
			extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata)
		}
	)
end

-- Calculate the wiki specific Weight for the event
function BroadcasterCard.getWeight()
	local tPrizePool = Variables.varDefault('tournament_prizepoolusd') or 1
	local tier = Variables.varDefault('tournament_liquipediatier')
	local tierType = Variables.varDefault('tournament_liquipediatiertype')

	if Weight then
		return Weight.run(tier, tPrizePool, tierType)
	end

	return Template.safeExpand(mw.getCurrentFrame(), 'BroadcastWeight', {tier, tPrizePool})
end

return BroadcasterCard
