---
-- @Liquipedia
-- page=Module:TeamList/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local TeamCard = Lua.import('Module:TeamList/Starcraft/TeamCard')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Opponent = Lua.import('Module:Opponent/Custom')

local TeamParticipantsController = Lua.import('Module:TeamParticipants/Controller')
local Tabs = Lua.import('Module:Tabs')

local TeamListWrapper = {}

---@class StarcraftTeamList
---@operator call(table): StarcraftTeamList
---@field args table
---@field config StarcraftTeamListConfig
---@field sections StarcraftTeamListSection[]
---@field root Html?
local TeamList = Class.new(
	function(self, args)
		self.args = args
	end
)

---@param frame Frame
---@return Renderable?
function TeamListWrapper.TemplateTeamList(frame)
	local args = Arguments.getArgs(frame)

	for _, item in pairs(args) do
		if item:find('<%s*br%s*/?>') then
			mw.ext.TeamLiquidIntegration.add_category('TeamList with br')
		end
	end

	local newArgs = TeamList(args):read():map()

	if Logic.readBool(args.generate) then
		return TeamListWrapper.generate(newArgs)
	end

	if Array.any(newArgs, function(section)
		return Array.any(section, function(opp)
			return Logic.isNotEmpty(opp.notes)
		end)
	end) then
		mw.ext.TeamLiquidIntegration.add_category('TeamList with notes')
		Array.forEach(newArgs, function(section)
			Array.forEach(section, function(opp)
				if Logic.isEmpty(opp.notes) then return end
				opp.notes = Array.map(opp.notes, function(note) return {note} end)
			end)
		end)
	end

	if not newArgs[2] then
		return TeamParticipantsController.fromTemplate(newArgs[1])
	end

	local tabArgs = {}
	Array.forEach(newArgs, function(tpArgs, index)
		if not tpArgs.title then
			mw.ext.TeamLiquidIntegration.add_category('TeamList with missing section title')
		end
		tabArgs['name' .. index] = tpArgs.title
		tabArgs['content' .. index] = TeamParticipantsController.fromTemplate(tpArgs)
	end)

	return Tabs.dynamic(tabArgs)
end

---@param args table[]
---@return string
function TeamListWrapper.generate(args)
	if not args[2] then
		return TeamListWrapper.generateSingle(args[1])
	end

	local parts = {'{{Tabs dynamic'}
	Array.forEach(args, function(tpArgs, index)
		table.insert(parts, '|name' .. index .. '=' .. tpArgs.title)
	end)
	table.insert(parts, '|This=1')
	table.insert(parts, '}}')

	Array.forEach(args, function(tpArgs, index)
		table.insert(parts, '{{Tabs dynamic/tab|' .. index .. '}}')
		table.insert(parts, TeamListWrapper.generateSingle(tpArgs))
	end)

	table.insert(parts, '{{Tabs dynamic/end}}')

	return table.concat(parts, '\n')
end

---@param args table
---@return string
function TeamListWrapper.generateSingle(args)
	local parts = {
		'{{TeamParticipants',
		TeamListWrapper.generateOuterConfig(args),
	}

	Array.forEach(args, function(oppArgs)
		table.insert(parts, TeamListWrapper.generateOpponent(oppArgs))
	end)
	table.insert(parts, '}}')

	return table.concat(parts, '\n')
end

---@param args table
---@return string?
function TeamListWrapper.generateOuterConfig(args)
	local params = {
		'showplayerinfo',
		'date',
		'enrichPlayerDates',
	}

	local parts = Array.map(params, function(param)
		local value = args[param]
		if Logic.isEmpty(value) then return end
		return '|' .. param .. '=' .. value
	end)

	local store = args.store == false and 'false' or '<includeonly>false</includeonly>'
	table.insert(parts, '|store=' .. store)

	return table.concat(parts)
end


---@param args table
---@return string
function TeamListWrapper.generateOpponent(args)
	local parts = {
		'\t|{{Opponent|' .. args.template,
		'\t\t|import=false',
		Logic.isNotEmpty(args.date) and ('\t\t|date=' .. args.date) or nil,
	}

	table.insert(parts, '\t\t|players={{Persons')
	Array.forEach(args.players, function(playerArgs)
		table.insert(parts, TeamListWrapper.generatePlayer(playerArgs))
	end)
	table.insert(parts, '\t\t}}')

	if Logic.isNotEmpty(args.notes) then
		table.insert(parts, '\t\t|notes={{Notes')
		Array.forEach(args.notes, function(note)
			table.insert(parts, '\t\t\t|{{Note|' .. note .. '}}')
		end)
		table.insert(parts, '\t\t}}')
	end

	table.insert(parts, '\t}}')

	return table.concat(parts, '\n')
end

---@param args table
---@return string
function TeamListWrapper.generatePlayer(args)
	local parts = {
		'\t\t\t|{{Person|' .. args.name,
	}

	local add = function(param)
		local value = args[param]
		if Logic.isEmpty(value) then return end
		table.insert(parts, '|' .. param .. '=' .. tostring(value))
	end

	local params = {
		'link',
		'flag',
		'faction',
		'team',
		'role',
		'played',
		'results',
		'status',
	}
	Array.forEach(params, add)

	table.insert(parts, '}}')

	return table.concat(parts)
end

---@return self
function TeamList:read()
	self.config = TeamList.readConfig(self.args)
	self:readSections()

	return self
end

---@return table[]
function TeamList:map()
	return Array.map(self.sections, function(section)
		local config = section.config

		local args = {
			title = section.title or config.title,
			showplayerinfo =  config.playerInfoButton and 'true' or nil,
			date = config.resolveDate,
			store = not config.noStorage,
			enrichPlayerDates = 'false',
		}

		if args.title and config.showCountBySection then
			args.title = args.title .. ' (' .. (config.count or #section.entries) .. ')'
		end

		if config.sortTeams then
			Array.sortInPlaceBy(section.entries, function(entry) return entry.name:lower() end)
		end

		return Table.mergeInto(args, Array.map(section.entries, TeamList.mapEntry))
	end)
end

---@param entry StarcraftTeamCard
---@return table
function TeamList.mapEntry(entry)
	local opp = entry.opponent
	local notes = {opp.note}
	local args = {
		import = 'false', --- disallow this shit as it just fucks up things ...
		players = Array.map(opp.players, function(player)
			table.insert(notes, player.note)
			return TeamList.mapPlayer(player)
		end),
		template = opp.template,
		date = opp.date,
	}
	args.notes = notes

	if opp.dq then
		mw.ext.TeamLiquidIntegration.add_category('TeamList with dq opponent')
	end

	return args
end

---@param player StarcraftTeamCardPlayer
---@return table
function TeamList.mapPlayer(player)
	local args = {
		name = player.displayName or player.pageName,
		link = player.pageName,
		flag = player.flag,
		faction = player.faction,
		team = player.mainTeamPage,
	}

	if player.dnp then
		args.played = 'false'
	end
	args.role = player.captain and 'Captain' or nil

	if player.dq then
		args.status = 'former'
		args.result = 'false'
	elseif player.withdraw then
		args.status = 'former'
	end

	return args
end

---@class StarcraftTeamListConfig: StarcraftTeamCardConfig
---@field showCountBySection boolean
---@field count number?
---@field title string?
---@field sortTeams boolean
---@field playerInfoButton boolean
---@field matchGroupSpec {matchGroupIds: string[], pageNames: string[]}?
---@field import boolean
---@field importOnlyQualified boolean

---@param args table
---@param parentConfig StarcraftTeamListConfig?
---@return StarcraftTeamListConfig
function TeamList.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	local matchGroupSpec = TournamentStructure.readMatchGroupsSpec(args)
	local import = matchGroupSpec ~= nil

	local config = {
		--display
		showCountBySection = Logic.readBool(args.showCountBySection or parentConfig.showCountBySection),
		count = tonumber(args.count),
		title = args.title,
		sortTeams = Logic.nilOr(Logic.readBoolOrNil(args.sortTeams), parentConfig.sortTeams, true),
		playerInfoButton = Logic.readBool(args.playerInfoButton),
		isAdhoc = Logic.nilOr(Logic.readBoolOrNil(args.adhoc), parentConfig.isAdhoc, false),
		--import
		matchGroupSpec = matchGroupSpec,
		import = import,
		importOnlyQualified = Logic.readBool(args.onlyQualified),
		autoDnp = Logic.nilOr(Logic.readBoolOrNil(args.autoDnp), import or parentConfig.import or nil),
	}

	return Table.merge(TeamCard.readConfig(args, parentConfig), config)
end

function TeamList:readSections()
	self.sections = {}

	local firstSection = Json.parseIfTable(self.args[1])
	if not firstSection then
		return
	elseif firstSection.type ~= 'section' then
		--assume no sections and treat whole list as first section
		table.insert(self.sections, self:readSection(self.args))
		return
	end

	Array.forEach(self.args, function(potentialSection)
		local sectionArgs = Json.parseIfTable(potentialSection)
		assert(sectionArgs and sectionArgs.type == 'section', 'Invalid input: "' .. potentialSection .. '" is not a section')
		table.insert(self.sections, self:readSection(sectionArgs))
	end)
end

---@class StarcraftTeamListSection
---@field config StarcraftTeamListConfig
---@field title string?
---@field entries StarcraftTeamCard[]

---@param sectionArgs table
---@return StarcraftTeamListSection
function TeamList:readSection(sectionArgs)
	local section = {config = TeamList.readConfig(sectionArgs, self.config), title = sectionArgs.title}
	local entriesByName = {}

	sectionArgs = Array.extractValues(Table.filterByKey(sectionArgs, function(key) return type(key) == 'number' end))

	Array.forEach(sectionArgs, function(teamCardArgs)
		local entry = TeamCard(Table.merge({date = section.config.resolveDate}, Json.parseIfTable(teamCardArgs)))
		entriesByName[entry.name] = entry
	end)

	section.entries = Array.map(self:import(section.config, entriesByName), function(entry)
		return entry:getConfig(section.config):sync(self.config.matchGroupSpec)
	end)

	return section
end

---@param config StarcraftTeamListConfig
---@param entriesByName table<string, StarcraftTeamCard>
---@return StarcraftTeamCard[]
function TeamList:import(config, entriesByName)
	if not config.import then
		return Array.extractValues(entriesByName)
	end

	local matchRecords = TeamList._fetchMatchRecords(config.matchGroupSpec)
	if Table.isEmpty(matchRecords) then
		return Array.extractValues(entriesByName)
	end
	---@cast matchRecords -nil
	return TeamList._entriesFromMatchRecords(matchRecords, config, entriesByName)
end

---@param matchGroupSpec {matchGroupIds: string[], pageNames: string[]}
---@return table[]
function TeamList._fetchMatchRecords(matchGroupSpec)
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(TournamentStructure.getMatch2Filter(matchGroupSpec)),
		query = 'pagename, match2bracketdata, match2opponents, winner',
		order = 'date asc',
		limit = 5000,
	})
end

---@param matchRecords table[]
---@param config StarcraftTeamListConfig
---@param entriesByName table<string, StarcraftTeamCard>
---@return StarcraftTeamCard[]
function TeamList._entriesFromMatchRecords(matchRecords, config, entriesByName)
	Array.forEach(matchRecords, function(matchRecord)
		Array.forEach(matchRecord.match2opponents, function(opponentRecord, opponentIndex)
			if not TeamList._shouldInclude(opponentIndex, matchRecord, config.importOnlyQualified) then
				return
			end

			if entriesByName[opponentRecord.name] then
				return
			end

			entriesByName[opponentRecord.name] = TeamList._entryFromOpponentRecord(opponentRecord, config.resolveDate)
		end)
	end)

	return Array.extractValues(entriesByName)
end

---@param opponentIndex integer
---@param matchRecord table
---@param importOnlyQualified boolean?
---@return boolean
function TeamList._shouldInclude(opponentIndex, matchRecord, importOnlyQualified)
	local bracketData = matchRecord.match2bracketdata
	return not importOnlyQualified or Logic.readBool(bracketData.quallose) or
		Logic.readBool(bracketData.qualwin) and tonumber(matchRecord.winner) == opponentIndex
end

---@param opponentRecord table
---@param resolveDate string
---@return StarcraftTeamCard?
function TeamList._entryFromOpponentRecord(opponentRecord, resolveDate)
	if opponentRecord.type ~= Opponent.team or not opponentRecord.template or opponentRecord.template:lower() == 'tbd' then
		return
	end

	local opponentArgs = {
		team = opponentRecord.template,
		date = resolveDate
	}

	Array.forEach(opponentRecord.match2players, function(playerRecord, playerIndex)
		local prefix = 'p' .. playerIndex
		opponentArgs[prefix] = playerRecord.displayname
		opponentArgs[prefix .. 'link'] = playerRecord.name
		opponentArgs[prefix .. 'flag'] = playerRecord.flag
		opponentArgs[prefix .. 'faction'] = (playerRecord.extradata or {}).faction
	end)

	return TeamCard(opponentArgs)
end

return TeamListWrapper
