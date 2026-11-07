--- Triple Comment to Enable our LLS Plugin
describe('Widget/Documentation/Parameters', function()
	local DocumentationParameters = require('Module:Widget/Documentation/Parameters')

	local originalPreprocess

	before_each(function()
		originalPreprocess = mw.frame.preprocess
		mw.frame.preprocess = function(_, text) return text end
	end)

	after_each(function()
		mw.frame.preprocess = originalPreprocess
	end)

	---@param parameters ArgSchemaParameter[]
	---@param context table?
	---@return string
	local function render(parameters, context)
		return tostring(DocumentationParameters{parameters = parameters, context = context or {}})
	end

	it('lists the names with their default and the description', function()
		assert.are_equal(
			'<dl><dt><code class="nowrap">&#124;store&#61;false</code></dt><dd>Stores it.</dd></dl>',
			render{{name = 'store', type = 'boolean', default = false, description = 'Stores it.'}}
		)
	end)

	it('lists indexed names by their first indexes, followed by their aliases', function()
		assert.are_equal(
			'<dl><dt><code class="nowrap">&#124;r1points&#61;</code>, <code class="nowrap">&#124;r2points&#61;</code>, '
				.. '…, <code class="nowrap">&#124;points&#61;</code></dt><dd>Points.</dd></dl>',
			render{{name = 'r{round}points', aliases = {'points'}, description = 'Points.'}}
		)
	end)

	it('lists unnamed parameters by their example, as editors write them', function()
		assert.are_equal(
			'<dl><dt><code class="nowrap">&#124;&#123;&#123;TeamOpponent&#124;...&#125;&#125;</code></dt>'
				.. '<dd>Opponents.</dd></dl>',
			render{{name = '{opponent}', example = '{{TeamOpponent|...}}', description = 'Opponents.'}}
		)
	end)

	it('leaves out hidden parameters and the ones whose condition does not apply', function()
		local parameters = {
			{name = 'tabletype', hidden = true, description = 'Type.'},
			{name = 'placements', condition = function(context) return context.swiss end, description = 'Placements.'},
		}
		assert.are_equal('', render(parameters))
		assert.is_truthy(render(parameters, {swiss = true}):find('&#124;placements&#61;', 1, true))
	end)
end)
