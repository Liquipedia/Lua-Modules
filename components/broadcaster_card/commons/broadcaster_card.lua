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
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Weight = Lua.requireIfExists('Module:BroadCasterWeight')

local TBD = 'TBD'

local BroadcasterCard = {}

---@class broadCasterData
---@field id string
---@field name string
---@field displayName string?
---@field page string
---@field language string?
---@field position string
---@field weight number
---@field sort string|number
---@field date string
---@field flag string?
---@field isManualInput boolean

---Template entry point
---@param frame Frame
---@return string
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
	---@cast position string

	if args.title then
		title = args.title
	elseif position == TBD then
		title = Abbreviation.make(TBD, 'To Be Determined')
	else
		-- Create a title from the position.
		local positions = Array.map(
			mw.text.split(position, '/'),
			String.trim
		)
		if args.b2 then
			positions = Array.map(positions, BroadcasterCard._pluralisePosition)
		end
		title = table.concat(positions, '/') .. ':'
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
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(args[prefix .. 'link'] or caster):gsub(' ','_')
		args[prefix .. 'flag' ] = Flags.CountryName(args[prefix .. 'flag' ])

		local name, nationality = BroadcasterCard.getData(args, prefix, link, restrictedQuery)
		local date = Variables.varDefault('tournament_enddate')

		local broadcaster = {
			id = caster,
			name = name or '',
			displayName = args[prefix .. 'name_o'],
			page = link,
			language = language,
			position = position,
			weight = BroadcasterCard.getWeight(),
			flag = (nationality or ''):lower(),
			date = date,
			sort = tonumber(args[prefix .. 'sort'])
		}
		--if entered name and stored name as well as entered flag and stored flag match mark it as manual input
		broadcaster.isManualInput = args[prefix .. 'name'] == name and args[prefix .. 'flag' ] == nationality

		broadcaster.sort = BroadcasterCard.sortValue(broadcaster, args.sort, casterIndex)

		BroadcasterCard.setLPDB(broadcaster, args.status)

		table.insert(casters, broadcaster)
	end

	if Table.isEmpty(casters) then
		return outputList .. '\n**' .. Abbreviation.make('TBA', 'To Be Announced')
	end

	table.sort(casters, function(a, b) return a.sort < b.sort or (a.sort == b.sort and a.id:lower() < b.id:lower()) end)

	for _, broadcaster in ipairs(casters) do
		local alwaysShowName = Logic.readBool(args.alwaysShowName)
		outputList = outputList .. BroadcasterCard._display(broadcaster, {alwaysShowName = alwaysShowName})
	end

	return outputList
end

---@param broadcaster broadCasterData
---@param options {alwaysShowName: boolean}
---@return string
function BroadcasterCard._display(broadcaster, options)
	local displayName = broadcaster.displayName or broadcaster.name

	if String.isNotEmpty(displayName) and (options.alwaysShowName or displayName ~= broadcaster.id) then
		displayName = ('&nbsp;(' .. displayName ..')')
	else
		displayName = ''
	end

	return '\n**' .. Flags.Icon{flag = broadcaster.flag, shouldLink = true}
		.. '&nbsp;[[' .. broadcaster.page .. '|'.. broadcaster.id .. ']]'
		.. displayName
end

---@param position string
---@return string
function BroadcasterCard._pluralisePosition(position)
	return String.endsWith(position, 's') and position or (position .. 's')
end

---Fetches information about the caster
---@param args table
---@param prefix string
---@param casterPage string
---@param restrictedQuery boolean
---@return string?, string?
function BroadcasterCard.getData(args, prefix, casterPage, restrictedQuery)
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. casterPage .. ']]',
		query = 'romanizedname, name, pagename, nationality',
		limit = 1,
	})

	if type(data) == 'table' and data[1] then
		return String.nilIfEmpty(data[1].romanizedname) or data[1].name, data[1].nationality
	end

	local name, flag = args[prefix .. 'name'], args[prefix .. 'flag']

	if String.isNotEmpty(name) and String.isNotEmpty(flag) or restrictedQuery then
		return name, flag
	end

	data = mw.ext.LiquipediaDB.lpdb('broadcasters', {
		conditions = '[[extradata_manualinput::true]] AND [[page::' .. casterPage .. ']]'
			.. ' AND ([[name::!]] OR [[flag::!]])'
			.. ' AND [[pagename::!' .. mw.title.getCurrentTitle().text:gsub(' ', '_') .. ']]',
		query = 'name, flag',
		groupby = 'flag asc, name asc',
		limit = 5000,
	})

	if type(data) ~= 'table' or not data[1] then
		return name, flag
	end

	return BroadcasterCard._findUnique(data, 'name', casterPage) or name,
		BroadcasterCard._findUnique(data, 'flag', casterPage) or flag
end

---@param data {name: string?, flag: string?}
---@param property 'name'|'flag'
---@param page string
---@return string?
function BroadcasterCard._findUnique(data, property, page)
	--remove all empty values
	local foundItems = Array.filter(data, function(item) return String.isNotEmpty(item[property]) end)
	--extract the array of tables to an array of values want to look at
	foundItems = Array.map(foundItems, Operator.property(property))

	--remove duplicates
	foundItems = Array.unique(foundItems)

	--if we only have 1 unique element then we have a definitive query, return the value
	if #foundItems == 1 then
		return foundItems[1]
	elseif #foundItems > 1 then
		mw.logObject(foundItems, property .. 's not unique for ' .. page)
	end
end

---Determines the sort value for a broadcaster
---@param broadcaster broadCasterData
---@param sortMode string|number|nil
---@param casterIndex integer
---@return string|number
function BroadcasterCard.sortValue(broadcaster, sortMode, casterIndex)
	if sortMode == 'flag' then
		return broadcaster.flag
	elseif sortMode == 'manual' then
		return 99 - (broadcaster.sort or 0)
	elseif sortMode == 'id' then
		return broadcaster.id:lower()
	end

	return casterIndex
end

---Stores the broadcaster data into Lpdb
---@param caster broadCasterData
---@param status string?
function BroadcasterCard.setLPDB(caster, status)
	local smName = Variables.varDefault('show_match_name') or ''
	local extradata = {status = '', manualinput = tostring(caster.isManualInput)}
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
---@return number
function BroadcasterCard.getWeight()
	local tPrizePool = Variables.varDefault('tournament_prizepoolusd') or 1
	local tier = Variables.varDefault('tournament_liquipediatier')
	local tierType = Variables.varDefault('tournament_liquipediatiertype')

	if Weight then
		return Weight.run(tier, tPrizePool, tierType)
	end

	return Template.safeExpand(mw.getCurrentFrame(), 'BroadcastWeight', {tier, tPrizePool}) --[[@as number]]
end

return BroadcasterCard
