---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Player/Ext/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

local playerVars = PageVariableNamespace({namespace = 'Player', cached = true})

local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})

--- Asks LPDB for the team a player belonged to on a page. For specific uses only.
---@param resolvedPageName string
---@date resolvedPageName string
function PlayerExt.fetchTeamHistoryEntry(resolvedPageName, date)
	if Logic.isEmpty(resolvedPageName) then
		return
	end

	local conditions = {
		'[[type::Notable]]',
		'[[pagename::' .. mw.title.getCurrentTitle().text:gsub(' ', '_') .. ']]',
		'[[name::' .. resolvedPageName .. ']]',
	}
	local datapoint = mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 1,
		conditions = table.concat(conditions, ' AND '),
		query = 'information',
	})[1]

	if datapoint and Logic.isNotEmpty(datapoint.information) then
		return {
			joinDate = date,
			leaveDate = date,
			template = datapoint.information:lower(),
		}
	end
end

return PlayerExt
