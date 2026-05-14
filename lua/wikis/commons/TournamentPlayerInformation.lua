---
-- @Liquipedia
-- page=Module:TournamentPlayerInformation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Box = Lua.import('Module:Widget/Basic/Box')
local Button = Lua.import('Module:Widget/Basic/Button')
local CopyToClipboard = Lua.import('Module:Widget/Basic/CopyToClipboard')
local Dialog = Lua.import('Module:Widget/Basic/Dialog')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class EnrichedStandardPlayer: standardPlayer
---@field name string?
---@field image string?
---@field birthDate string?
---@field currentTeam string?
---@field links table?
---@field role string?
---@field fromOpponentType OpponentType

---@class TournamentPlayerInfo
---@operator call(table): TournamentPlayerInfo
---@field config {opponenttype: OpponentType?}
---@field tournament StandardTournament
---@field protected data EnrichedStandardPlayer[]
local TournamentPlayerInfo = Class.new(function(self, ...) self:init(...) end)

---@param frame Frame
---@return Widget|string
function TournamentPlayerInfo.create(frame)
	local args = Arguments.getArgs(frame)
	local tournamentPlayerInfo = TournamentPlayerInfo(args)

	if not tournamentPlayerInfo:isValidTournament() then
		return 'No conditions set.'
	end

	return tournamentPlayerInfo:query():build()
end

---@param args table
---@return self
function TournamentPlayerInfo:init(args)
	self.config = {
		opponenttype = Logic.nilIfEmpty(args.opponenttype)
	}

	local pageName = Logic.emptyOr(args.pagename, args.page)

	assert(pageName, 'pagename must be specified')

	self.tournament = Tournament.getTournament(pageName) or {}

	return self
end

---@return boolean
function TournamentPlayerInfo:isValidTournament()
	return Logic.isNotEmpty(self.tournament)
end

---@return boolean
function TournamentPlayerInfo:tournamentIsFinished()
	return self.tournament.phase == 'FINISHED'
end

---@return self
function TournamentPlayerInfo:query()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('pagename'), Comparator.eq, self.tournament.pageName),
		ConditionNode(ColumnName('opponentplayers'), Comparator.neq, ''),
		ConditionNode(ColumnName('mode'), Comparator.neq, 'award_individual'),
	}

	if self.config.opponenttype then
		conditions:add(ConditionNode(ColumnName('opponenttype'), Comparator.eq, self.config.opponenttype))
	end

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		limit = 5000,
		order = 'opponentname asc',
	})

	return self:_parseRecords(data)
end

---@private
---@param records placement[]
---@return self
function TournamentPlayerInfo:_parseRecords(records)
	local players = Array.flatMap(records, function (record)
		local opponent = Opponent.fromLpdbStruct(record)

		return Array.map(opponent.players, function (player, playerIndex)
			player.extradata = player.extradata or {}
			player.extradata.index = playerIndex
			if opponent.type == Opponent.team then
				player.team = opponent.template
			end

			return Table.merge(self:queryPlayerInfo(player), {fromOpponentType = opponent.type})
		end)
	end)

	-- sort by displayName if we have no team opponents
	if self:_hasNoTeamOpponents(players) then
		self.data = Array.sortBy(players, function(x) return x end, function(a, b)
			return (a.displayName or ''):lower() < (b.displayName or ''):lower()
		end)
		return self
	end

	self.data = Array.sortBy(players, function(x) return x end, function (a, b)
		if Logic.isEmpty(a.team) then
			return Logic.isEmpty(b.team)
		elseif Logic.isEmpty(b.team) then
			return Logic.isEmpty(a.team)
		elseif a.team ~= b.team then
			return a.team < b.team
		end
		-- TODO: sort by role when it becomes available in queried placement data
		return a.extradata.index < b.extradata.index
	end)
	return self
end

---@protected
---@param player standardPlayer
---@return EnrichedStandardPlayer
function TournamentPlayerInfo:queryPlayerInfo(player)
	local playerData = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(player.pageName))),
		query = 'name, image, birthdate, team, links, extradata',
		limit = 1
	})[1]
	if playerData then
		local extradata = playerData.extradata or {}
		return Table.merge(player, {
			name = extradata.firstname and table.concat({extradata.firstname, extradata.lastname}, ' ') or playerData.name,
			image = playerData.image,
			birthDate = playerData.birthdate,
			currentTeam = playerData.team,
			links = playerData.links,
			currentRole = extradata.role,
		})
	end
	local squadPlayerData = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		conditions = tostring(ConditionNode(ColumnName('link'), Comparator.eq, Page.pageifyLink(player.pageName))),
		limit = 1,
		query = 'name',
		order = 'joindate desc'
	})[1]
	---@cast player EnrichedStandardPlayer
	if squadPlayerData then
		player.name = squadPlayerData.name
	end
	return player
end

---@private
---@param players EnrichedStandardPlayer[]
---@return {averageAge: integer, youngest: EnrichedStandardPlayer, oldest: EnrichedStandardPlayer}?
function TournamentPlayerInfo:_calculateAgeData(players)
	if not self.tournament.startDate then
		return
	end
	local playersWithBirthDate = Array.filter(players, function (player)
		return Logic.isNotEmpty(player.birthDate) and player.birthDate ~= DateExt.defaultDate
	end)
	if Logic.isEmpty(playersWithBirthDate) then
		return
	end
	local averageAge = Array.reduce(playersWithBirthDate, function (aggregate, player)
		return aggregate + DateExt.readTimestamp(player.birthDate)
	end, 0) / #playersWithBirthDate --[[@as integer]]
	local playersByAge = Array.sortBy(playersWithBirthDate, FnUtil.identity, function (a, b)
		if a.birthDate ~= b.birthDate then
			return a.birthDate > b.birthDate
		end
		return a.displayName < b.displayName
	end)

	return {
		averageAge = self.tournament.startDate.timestamp - averageAge,
		youngest = playersByAge[1],
		oldest = playersByAge[#playersByAge],
	}
end

---@return Widget
function TournamentPlayerInfo:build()
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		self:buildIntro(),
		Box{
			children = WidgetUtil.collect(
				self:buildOverallAgeTable(),
				self:buildTeamAgeTable()
			)
		},
		self:buildPlayersTable()
	)}
end

---@protected
---@return Widget
function TournamentPlayerInfo:buildIntro()
	local tournament = self.tournament
	return Div{
		css = {['font-style'] = 'italic'},
		children = WidgetUtil.collect(
			'This automatically generated table is based on data from ',
			Link{link = tournament.pageName, children = tournament.displayName},
			'.',
			Logic.isNotEmpty(tournament.startDate) and {
				' Age at tournament start, ',
				DateExt.formatTimestamp('F j, Y', tournament.startDate.timestamp),
				'.'
			} or nil,
			' ',
			CopyToClipboard{
				children = '[Copy URL to clipboard]',
				textToCopy = tostring(mw.uri.fullUrl('Special:RunQuery/Tournament player information', {
					pfRunQueryFormName = 'Tournament player information',
					['TPI[page]'] = tournament.pageName,
					wpRunQuery = 'Run query'
				})),
				successText = 'Success!'
			}
		)
	}
end

---@private
---@param ageInSeconds integer?
---@return string
function TournamentPlayerInfo:_formatAge(ageInSeconds)
	if not ageInSeconds then
		return '-'
	end
	return mw.getContentLanguage():formatDuration(ageInSeconds, {'years', 'days'})
end

---@private
---@param player EnrichedStandardPlayer
---@return (string|integer|Widget|Html)[]
function TournamentPlayerInfo:_displayPlayerWithAge(player)
	return {
		PlayerDisplay.InlinePlayer{player = player},
		' (',
		DateExt.calculateAge(self.tournament.startDate.timestamp, player.birthDate),
		')'
	}
end

---@protected
---@return Widget?
function TournamentPlayerInfo:buildOverallAgeTable()
	local overallData = self:_calculateAgeData(self.data)
	if not overallData then
		return
	end
	return TableWidgets.Table{
		css = {margin = '1em 0'},
		children = {
			TableWidgets.TableHeader{children = TableWidgets.Row{
				children = {
					TableWidgets.CellHeader{children = 'Average Age'},
					TableWidgets.CellHeader{children = 'Youngest'},
					TableWidgets.CellHeader{children = 'Oldest'},
				}
			}},
			TableWidgets.TableBody{children = TableWidgets.Row{children = {
				TableWidgets.Cell{children = self:_formatAge(overallData.averageAge)},
				TableWidgets.Cell{children = self:_displayPlayerWithAge(overallData.youngest)},
				TableWidgets.Cell{children = self:_displayPlayerWithAge(overallData.oldest)},
			}}}
		}
	}
end

---@protected
---@return Widget?
function TournamentPlayerInfo:buildTeamAgeTable()
	if self:_hasNoTeamOpponents(self.data) then
		return
	end
	local _, teamPlayers = Array.groupBy(self.data, function (player) return player.team end)
	local ageDataByTeam = Table.mapValues(teamPlayers, function (players) return self:_calculateAgeData(players) end)

	if Logic.isEmpty(ageDataByTeam) then
		return
	end

	---@type Widget[]
	local teamTableRows = {}

	for team, teamData in Table.iter.spairs(ageDataByTeam, function (tbl, a, b)
		if tbl[a].averageAge ~= tbl[b].averageAge then
			return tbl[a].averageAge < tbl[b].averageAge
		end
		return a < b
	end) do
		Array.appendWith(teamTableRows, TableWidgets.Row{children = {
			TableWidgets.Cell{children = OpponentDisplay.InlineTeamContainer{template = team, style = 'hybrid'}},
			TableWidgets.Cell{children = self:_formatAge(teamData.averageAge)},
			TableWidgets.Cell{children = self:_displayPlayerWithAge(teamData.youngest)},
			TableWidgets.Cell{children = self:_displayPlayerWithAge(teamData.oldest)},
		}})
	end

	return TableWidgets.Table{
		tableClasses = {'prizepooltable', 'collapsed'},
		tableAttributes = {
			['data-cutafter'] = 3,
			['data-opentext'] = '4 to ' .. #teamTableRows,
			['data-closetext'] = '4 to ' .. #teamTableRows
		},
		css = {
			margin =  '1em 0',
		},
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = TableWidgets.Row{children = {
					TableWidgets.CellHeader{children = 'Team'},
					TableWidgets.CellHeader{children = 'Average Age'},
					TableWidgets.CellHeader{children = 'Youngest'},
					TableWidgets.CellHeader{children = 'Oldest'}
				}}
			},
			TableWidgets.TableBody{children = teamTableRows}
		)
	}
end

---@protected
---@return Widget
function TournamentPlayerInfo:buildPlayersTable()
	return TableWidgets.Table{
		css = {margin = '10px 0'},
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'center'},
			{align = 'left'},
			{
				align = 'left',
				unsortable = true,
			},
			{
				align = 'left',
				sortType = 'isoDate',
			},
			{align = 'left'},
			self:tournamentIsFinished() and {align = 'left'} or nil,
			{
				align = 'left',
				unsortable = true,
			}
		),
		children = {
			TableWidgets.TableHeader{children = TableWidgets.Row{
				children = WidgetUtil.collect(
					TableWidgets.CellHeader{},
					TableWidgets.CellHeader{children = 'Player'},
					TableWidgets.CellHeader{children = 'Photo'},
					TableWidgets.CellHeader{children = 'Born'},
					TableWidgets.CellHeader{
						align = 'left',
						children = 'Team'
					},
					self:tournamentIsFinished() and {
						TableWidgets.CellHeader{
							align = 'left',
							children = 'Current Team'
						}
					} or nil,
					TableWidgets.CellHeader{children = 'Links'}
				)
			}},
			TableWidgets.TableBody{children = Array.map(self.data, function (player)
				return self:buildPlayerRow(player)
			end)}
		}
	}
end

---@protected
---@param player EnrichedStandardPlayer
---@return Widget
function TournamentPlayerInfo:buildPlayerRow(player)
	---@return string|(string|integer)[]?
	local function displayBirthDateWithAge()
		if not self.tournament.startDate then
			return (player.birthDate ~= DateExt.defaultDate) and player.birthDate or nil
		end
		if not player.birthDate or player.birthDate == DateExt.defaultDate then
			return
		end
		return {
			player.birthDate,
			' (',
			DateExt.calculateAge(self.tournament.startDate.timestamp, player.birthDate),
			')'
		}
	end

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{children = Flags.Icon{flag = Logic.emptyOr(player.flag, 'unknown'), shouldLink = false}},
		TableWidgets.Cell{
			attributes = {
				['data-sort-value'] = player.displayName
			},
			children = WidgetUtil.collect(
				Link{link = player.pageName, children = player.displayName},
				Logic.isNotEmpty(player.name) and HtmlWidgets.Span{
					css = {
						display = 'block',
						['font-size'] = 'small',
						['line-height'] = 1
					},
					children = player.name
				} or nil
			)
		},
		TableWidgets.Cell{children = Logic.isNotEmpty(player.image) and Dialog{
			trigger = Button{
				children = {
					'Show',
					HtmlWidgets.Span{
						classes = {'mobile-hide'},
						children = ' photo'
					}
				},
				variant = 'secondary',
				size = 'xs',
			},
			title = {
				'Photo of ',
				PlayerDisplay.InlinePlayer{player = player}
			},
			children = Image{
				imageLight = player.image,
				size = '400x200px'
			},
		} or nil},
		TableWidgets.Cell{
			attributes = {
				['data-sort-value'] = (player.birthDate ~= DateExt.defaultDate) and player.birthDate or nil
			},
			children = displayBirthDateWithAge()
		},
		TableWidgets.Cell{children = Logic.isNotEmpty(player.team) and OpponentDisplay.InlineTeamContainer{
			style = 'hybrid',
			template = player.team
		} or nil},
		self:tournamentIsFinished() and {
			TableWidgets.Cell{children = Logic.isNotEmpty(player.currentTeam) and OpponentDisplay.InlineTeamContainer{
				style = 'hybrid',
				template = player.currentTeam
			} or nil}
		} or nil,
		TableWidgets.Cell{children = Array.interleave(
			Array.extractValues(Table.map(player.links or {}, function(key, link)
				return key, Link{
					link = link,
					children = Links.makeIcon(Links.removeAppendedNumber(key), 21),
					linktype = 'external'
				}
			end), Table.iter.spairs),
			' '
		)}
	)}
end

---@private
---@param players EnrichedStandardPlayer[]
---@return boolean
function TournamentPlayerInfo:_hasNoTeamOpponents(players)
	return Array.all(players, function(player) return player.fromOpponentType ~= Opponent.team end)
end

return TournamentPlayerInfo
