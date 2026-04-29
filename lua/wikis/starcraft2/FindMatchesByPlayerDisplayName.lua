---
-- @Liquipedia
-- page=Module:FindMatchesByPlayerDisplayName
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')

local FindMatchesByPlayerDisplayName = {}

---@param frame Frame
---@return Widget
function FindMatchesByPlayerDisplayName.run(frame)
	local args = Arguments.getArgs(frame)
	assert(Logic.isNotEmpty(args.p1), 'No player(s) specified')

	local displayNames = Array.flatten(Array.mapIndexes(function(index)
		if not args['p' .. index] then return end
		return {
			String.lowerCaseFirst(args['p' .. index]),
			String.upperCaseFirst(args['p' .. index]),
		}
	end))

	local data = mw.ext.LiquipediaDB.lpdb('match2player', {
		conditions = tostring(Condition.Util.anyOf(Condition.ColumnName('displayname'), displayNames)),
		query = 'pagename, name, displayname',
		groupby = 'pagename asc',
		limit = 5000,
	})

	return UnorderedList{
		children = Array.map(data, function(item)
			return {
				Link{link = item.pagename},
				' - name: ' .. item.name,
				' - displayName: ' .. item.displayname,
			}
		end)
	}
end

return FindMatchesByPlayerDisplayName
