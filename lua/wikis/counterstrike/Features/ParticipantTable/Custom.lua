---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local TextSanitizer = Lua.import('Module:TextSanitizer')
local Variables = Lua.import('Module:Variables')

local Controller = Lua.import('Module:Features/ParticipantTable/Controller')

local CustomConfig = {
	---@param lpdbData table
	---@param entry ParticipantTableEntry
	---@param config ParticipantTableConfig
	adjustLpdbData = function(lpdbData, entry, config)
		lpdbData.qualifier = TextSanitizer.stripHTML(config.title)
		lpdbData.extradata.status = Variables.varDefault('tournament_status', '')
	end
}

return {
	run = function(frame)
		return Controller.execute(frame, CustomConfig)
	end
}
