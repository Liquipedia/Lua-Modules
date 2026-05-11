---
-- for @Liquipedia by @hjpalpha
-- page=Module:TeamList/Starcraft
--

--[[

todo:
- sections marked with todo (especially mapping ...)
- debug
- double check if i missed some new args (i.e. compare to the md)

]]

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
---@return Html?
function TeamListWrapper.TemplateTeamList(frame)
	local args = Arguments.getArgs(frame)
	local teamList = TeamList(args):read()

	mw.logObject(teamList) -- todo: remove once mapping works

	local newArgs = teamList:map() -- todo
	teamList = nil

	mw.logObject(newArgs) -- todo: remove once mapping works

	if Logic.readBool(args.generate) then
		TeamListWrapper.generate(newArgs) -- todo
	end

	if not newArgs[2] then
		return TeamParticipantsController.fromTemplate(newArgs[1])
	end

	local tabArgs = {}
	Array.forEach(newArgs, function(tpArgs, index)
		if not tpArgs.title then
			-- todo: add tracking category
		end
		tabArgs['name' .. index] = tpArgs.title
		tabArgs['content' .. index] = TeamParticipantsController.fromTemplate(tpArgs)
	end)

	return Tabs.dynamic(tabArgs)
end

---@param table[]
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

---@param table
---@return string
function TeamListWrapper.generateSingle(args)
	local parts = {
		'{{TeamParticipants',
		TeamListWrapper.generateOuterConfig(args), --todo
	}

	Array.forEach(args, function(oppArgs)
		table.insert(parts, TeamListWrapper.generateOpponent(oppArgs))
	end)
	table.insert(parts, '}}')

	return table.concat(parts, '\n')
end

---@param table
---@return string?
function TeamListWrapper.generateOuterConfig(args)
--todo
end


---@param table
---@return string
function TeamListWrapper.generateOpponent(args)
	local parts = {
		'\n|{{Opponent|' .. args[1],
		'\n\n|players={{Persons',
	}

	Array.forEach(args.players, function(playerArgs)
		table.insert(parts, TeamListWrapper.generatePlayer(playerArgs))
	end)

	table.insert(parts, '\t\t}}')
	table.insert(parts, '\t}}')

	return table.concat(parts, '\n')
end

---@param table
---@return string
function TeamListWrapper.generatePlayer(args)
	local parts = {
		'\t\t\t|{{Person|',
	}

	-- todo (flag, role?, link?, faction, team?)

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
function TeamList.map()
-- todo
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
