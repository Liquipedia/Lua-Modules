---
-- @Liquipedia
-- page=Module:Infobox/Extension/SeriesAbbreviation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local SeriesAbbreviation = {}

---@param args {abbreviation: string?, series: string?}
---@return string?
function SeriesAbbreviation.fetch(args)
	if Logic.isNotEmpty(args.abbreviation) then
		return args.abbreviation
	elseif Logic.isEmpty(args.series) then
		return
	end

	local seriesPage = string.gsub(mw.ext.TeamLiquidIntegration.resolve_redirect(args.series), ' ', '_')
	local seriesData = mw.ext.LiquipediaDB.lpdb('series', {
			conditions = '[[pagename::' .. seriesPage .. ']] AND [[abbreviation::!]]',
			query = 'abbreviation',
			limit = 1
		})
	if type(seriesData) == 'table' and seriesData[1] then
		return seriesData[1].abbreviation
	end
end

return SeriesAbbreviation
