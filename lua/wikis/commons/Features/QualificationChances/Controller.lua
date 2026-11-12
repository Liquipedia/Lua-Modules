---
-- @Liquipedia
-- page=Module:Features/QualificationChances/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Opponent = Lua.import('Module:Opponent/Custom')
local Set = Lua.import('Module:Set')

local Html = Lua.import('Module:Widget/Html')
local Label = Lua.import('Module:Widget/Basic/Label')
local Switch = Lua.import('Module:Widget/Switch')
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

	local createdAtTimestamp = DateExt.readTimestamp((data.run or {}).createdAt)

	local limit = tonumber(args.limit)

	local teams = Array.sortBy(data.teams, function(team)
		return {-(team.chance_pct or 0), -(team.avg_rank_value or 0)}
	end)

	if limit then
		teams = Array.sub(teams, 1, limit)
	end

	---@type Set<string>
	local regions = Set{}

	local rows = Array.map(teams, function (team)
		if team.region then
			regions:add(team.region)
		end
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
	end)

	return Html.Div{
		classes = {'qualification-chances'},
		children = {
			Html.Div{
				classes = {'qualification-chances-toggle-container'},
				children = Array.map(
					Array.sortBy(regions:toArray(), FnUtil.identity),
					function (region)
						return Switch{
							switchGroup = 'qualification-' .. region:lower() .. '-chances',
							defaultActive = true,
							label = {
								'Show',
								'&nbsp;',
								Label{
									labelScheme = 'region',
									attributes = {['data-region'] = region:lower() or nil},
									children = region,
								}
							},
						}
					end
				),
			},
			TableWidgets.Table{
				striped = false,
				variant = 'themed',
				children = {
					TableWidgets.TableHeader{
						children = Header{stages = stages},
					},
					TableWidgets.TableBody{
						children = rows,
					},
				},
				footer = createdAtTimestamp and {
					'Last updated: ',
					Countdown.create{
						date = DateExt.toCountdownArg(createdAtTimestamp),
						timestamp = createdAtTimestamp,
						rawdatetime = true,
					},
				} or nil,
			}
		}
	}
end

return Controller
