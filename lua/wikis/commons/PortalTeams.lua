---
-- @Liquipedia
-- page=Module:PortalTeams
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local TeamService = Lua.import('Module:Service/Team')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Box = Lua.import('Module:Widget/Basic/Box')
local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')

local PortalTeams = {}

---@param frame Frame
---@return Renderable
function PortalTeams.active(frame)
	local teams = PortalTeams._fetch(frame, 'active')
	Array.sortInPlaceBy(teams, Operator.property('name'))

	return Box{children = Array.map(teams, PortalTeams._displayActiveTeam)}
end

---@param team team
---@return Renderable?
function PortalTeams._displayActiveTeam(team)
	local teamInfo = TeamService.getTeamByTemplate(team.pagename)
	local activeMembers = Array.filter((teamInfo or {}).members or {}, function(member)
		return member.status == 'active' and Logic.isNotEmpty(member.displayName)
	end)
	if Logic.isEmpty(activeMembers) then
		return
	end

	Array.sortInPlaceBy(activeMembers, Operator.property('displayName'))

	---@param member StandardTeamMember
	---@return Renderable
	local makeRow = function(member)
		local standardizedPlayer = Opponent.readSinglePlayerArgs{
			name = member.displayName,
			link = member.pageName,
			flag = member.nationality,
			faction = member.faction,
		}
		local role = Logic.nilIfEmpty(member.role)

		return TableWidgets.Row{
			children = {
				TableWidgets.Cell{
					children = {
						PlayerDisplay.InlinePlayer{player = standardizedPlayer},
						role and Html.Br{},
						role and Html.Small{children = {
							'(',
							role,
							')',
						}} or nil,
					},
				},
				TableWidgets.Cell{children = member.realName},
			},
		}
	end

	return TableWidgets.Table{
		tableClasses = {'collapsible', 'collapsed'},
		css = {width = '400px', ['margin-bottom'] = '0.5rem'},
		columns = {{}, {}},
		children = {
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = TableWidgets.CellHeader{
							colspan = 2,
							children = OpponentDisplay.InlineOpponent{
								opponent = {
									type = Opponent.team,
									template = team.pagename,
									extradata = {},
								},
							},
						},
					},
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = 'Id'},
							TableWidgets.CellHeader{children = 'Name'},
						},
					},
				},
			},
			TableWidgets.TableBody{children = Array.map(activeMembers, makeRow)}
		},
	}
end

---@param frame Frame
---@return Renderable
function PortalTeams.disbanded(frame)
	local queriedTeams = PortalTeams._fetch(frame, 'disbanded')

	---@param teams team[]
	---@return Renderable
	local makeColumn = function(teams)
		return UnorderedList{
			children = Array.map(teams, function(team)
				return OpponentDisplay.InlineOpponent{
					opponent = {
						type = Opponent.team,
						template = team.pagename,
						extradata = {},
					},
				}
			end)
		}
	end

	if #queriedTeams < 6 then
		return makeColumn(queriedTeams)
	end

	local numberOfTeamsPerColumn = math.ceil(#queriedTeams / 3)

	local columns = {
		Array.sub(queriedTeams, 1, numberOfTeamsPerColumn),
		Array.sub(queriedTeams, numberOfTeamsPerColumn + 1, 2 * numberOfTeamsPerColumn),
		Array.sub(queriedTeams, 2 * numberOfTeamsPerColumn + 1),
	}

	return Box{children = Array.map(columns, makeColumn)}
end

---@param frame Frame
---@param mode 'active'|'disbanded'
---@return team[]
function PortalTeams._fetch(frame, mode)
	local args = Arguments.getArgs(frame)
	local countries = Array.parseCommaSeparatedString(args.countries)

	local disbandDateComparator = mode == 'active' and Comparator.eq
		or mode == 'disbanded' and Comparator.neq
		or error('Invalid mode: "' .. (mode or '') .. '"')

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('name'), Comparator.neq, ''),
		ConditionNode(ColumnName('disbanddate'), disbandDateComparator, DateExt.defaultDate),
		ConditionUtil.anyOf(ColumnName('location'), countries),
	}

	local sortOrder = mode == 'active' and 'name asc' or 'disbanddate desc, name asc'

	return mw.ext.LiquipediaDB.lpdb('team', {
		conditions = tostring(conditions),
		query = 'pagename, name',
		order = sortOrder,
		limit = 5000,
	})
end

return PortalTeams
