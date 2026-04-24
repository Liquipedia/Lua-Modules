local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local GroupTableLeague = Lua.import('Module:GroupTableLeague/Starcraft/next/downstream')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GroupTableWrapper = {}

---@param args table
---@return Widget
function GroupTableWrapper.run(args)
	args = args or {}

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		GroupTableLeague.run(args),
		GroupTableWrapper._getMatchGroups(args)
	)}
end


---@private
---@param args table
---@return Renderable[]
function GroupTableWrapper._getMatchGroups(args)
	args.matchGroup1 = args.matchGroup1 or args.matchGroup
	local matchGroups = Array.mapIndexes(function(index)
		return args['matchGroup' .. index]
	end)

	if Logic.isNotEmpty(matchGroups) then
		return matchGroups
	end

	-- query the matchgroups
	local matchGroupIds = Array.mapIndexes(function(index)
		return args['matchGroupId' .. index]
	end)
	table.insert(matchGroupIds, args.id)
	table.insert(matchGroupIds, args.matchGroupId)

	return Array.map(matchGroupIds, function(id)
		local matchRecords = MatchGroupUtil.fetchMatchRecords(id)
		if not matchRecords then
			return
		end
		Variables.varDefine('match2bracket_' .. id, Json.stringify(matchRecords))
		if Logic.readBool(args.onlySetVarForMatchLists) then
			return
		end
		return MatchGroup.MatchGroupById{
			id = id,
			width = args.width,
			collapsed = args.collapsed or true,
			attached = args.attached or true,
		}
	end)
end

return Class.export(GroupTableWrapper)
