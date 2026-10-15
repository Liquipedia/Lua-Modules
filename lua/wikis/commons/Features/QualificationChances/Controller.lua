---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Opponent = Lua.import('Module:Opponent/Custom')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Header = Lua.import('Module:Features/QualificationChances/Components/Header')
local Row = Lua.import('Module:Features/QualificationChances/Components/Row')
local DataFetch = Lua.import('Module:Features/QualificationChances/Api/Fetch')

local Controller = {}

---@param frame Frame
---@return Renderable
function Controller.showQualificationChances(frame)
	local args = Arguments.getArgs(frame)

	local stages = Json.parseIfTable(args.stages)
	local data = DataFetch.fromWikiJson(args.datapage)

	local limit = tonumber(args.limit)

	local teams = Array.sortBy(data.teams, function(team)
		return {-(team.chance_pct or 0), -(team.avg_rank_value or 0)}
	end)

	if limit then
		teams = Array.sub(teams, 1, limit)
	end

	return TableWidgets.Table{
		striped = true,
		variant = 'themed',
		children = {
			TableWidgets.TableHeader{
				children = Header{stages = stages},
			},
			TableWidgets.TableBody{
				children = Array.map(teams, function (team)
					return Row{
						opponent = Opponent.readOpponentArgs{type = Opponent.team, template = team.team_id},
						region = team.region,
						chance = (team.chance_pct or 0) / 100,
						stages = Array.map(stages or {}, function(stage)
							local correctStage = Array.find(team.stages and team.stages.stages or {}, function (element)
								return stage == element.name
							end)
							return correctStage and ((correctStage.pct or 0) / 100) or 0
						end)
					}
				end),
			},
		},
	}
end

return Controller
