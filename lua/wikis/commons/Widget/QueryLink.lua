---
-- @Liquipedia
-- page=Module:Widget/QueryLink
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class QueryLinkParameters
---@field legacyForm string
---@field form string
---@field template string
---@field display string
---@field queryArgs table?
---@field execute boolean?

---@param props QueryLinkParameters
---@return Widget
local function QueryLink(props)
	-- legacy is only needed until lighthouse is fully ready
	---@return Renderable
	local makeLegacyQueryLink = function()
		local form = assert(Logic.nilIfEmpty(props.legacyForm), 'Missing legacyForm input when building query link')
		local prefix = assert(Logic.nilIfEmpty(props.template), 'Missing template input when building query link')

		local queryArgs = Table.map(props.queryArgs or {}, function(key, item)
			return prefix .. '[' .. key .. ']', item
		end)

		local link = tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. form,
			queryArgs
		)) .. (props.execute and '&_run' or '')

		return Html.Span{
			classes = { 'hide-when-lighthouse' },
			children = Link{
				linktype = 'external',
				children = props.display,
				link = link,
			}
		}
	end

	---@return Renderable
	local makeLighthouseQueryLink = function()
		local form = assert(Logic.nilIfEmpty(props.form), 'Missing form input when building query link')

		local link = tostring(mw.uri.fullUrl(
			'Special:RunQuery/' .. form,
			props.queryArgs or {}
		))

		return Html.Span {
			classes = { 'hide-when-mediawiki' },
			children = Link{
				linktype = 'external',
				children = props.display,
				link = link,
			}
		}
	end

	return Html.Fragment{
		children = {
			makeLegacyQueryLink(),
			makeLighthouseQueryLink()
		}
	}
end

return Component.component(QueryLink)
