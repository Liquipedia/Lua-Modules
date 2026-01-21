---
-- @Liquipedia
-- page=Module:Widget/Infobox/ShopMerch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')

local Button = Lua.import('Module:Widget/Basic/Button')
local Center = Lua.import('Module:Widget/Infobox/Center')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class InfoboxShopMerchWidget: Widget
---@operator call(table): InfoboxShopMerchWidget
---@field args table<string, string>
local ShopMerch = Class.new(Widget)
ShopMerch.defaultProps = {
	args = {},
}

local TARGET_HOST = 'links.liquipedia.net'

local MAX_URL_LENGTH = 2000

local SHOP_DEFAULT_LINK = 'https://links.liquipedia.net/tlstore'
local SHOP_DEFAULT_ICON = 'shopping_bag'
local SHOP_DEFAULT_TEXT = 'Shop Official Team Liquid Gear'


---Only allow slugs for `https://links.liquipedia.net/...`.
---@param shopLink string?
---@return string? normalizedUrl
local function normalizeAndValidateShopLink(shopLink)
	if String.isEmpty(shopLink) then
		return nil
	end

	if Logic.readBool(shopLink) then
		return SHOP_DEFAULT_LINK
	end
	---@cast shopLink -nil

	shopLink = shopLink:gsub('^/+', '')

	-- Security: Reject anything that looks like a full URL or contains forbidden characters.
	assert(not shopLink:find('://'), 'shoplink should only be a slug, not a full URL')
	assert(not shopLink:find('[%[%]%s<>\"]'), 'shoplink contains forbidden characters')
	assert(
		not shopLink:find(TARGET_HOST, 1, true),
		'shoplink should only be a slug, do not include "' .. TARGET_HOST .. '"'
	)

	local uri = mw.uri.new('https://' .. TARGET_HOST .. '/' .. shopLink)
	local url = tostring(uri)
	assert(#url <= MAX_URL_LENGTH, 'shoplink too long')

	return url
end

---@return Widget[]?
function ShopMerch:render()
	local args = self.props.args or {}

	local rawShopLink = String.trim(args.shoplink or '')
	if Logic.isEmpty(rawShopLink) then
		return
	end

	local shopLink = normalizeAndValidateShopLink(rawShopLink)
	if not shopLink then
		return
	end

	local children = WidgetUtil.collect(
		IconFa{iconName = SHOP_DEFAULT_ICON},
		' ',
		SHOP_DEFAULT_TEXT
	)

	return {
		Title{children = 'Shop Merch'},
		Center{children = {
			Button{
				linktype = 'external',
				link = shopLink,
				children = children,
			},
			I18n.translate('shop-merch-support-text'),
		}},
	}
end

return ShopMerch
