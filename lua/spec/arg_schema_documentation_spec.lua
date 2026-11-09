--- Triple Comment to Enable our LLS Plugin
describe('ArgSchema/Documentation', function()
	local ArgSchemaDocumentation = require('Module:ArgSchema/Documentation')
	local Lua = require('Module:Lua')

	local EXAMPLE = {
		parameters = {{name = 'store', type = 'boolean', default = false, description = 'Stores it.'}},
		header = {{
			name = 'placements',
			condition = function(context) return context.tabletype == 'swiss' end,
			description = 'Placements.',
		}},
	}

	local importStub
	local originalPreprocess

	before_each(function()
		local import = Lua.import
		importStub = stub(Lua, 'import', function(name, options)
			return name == 'Module:Example' and EXAMPLE or import(name, options)
		end)
		originalPreprocess = mw.frame.preprocess
		mw.frame.preprocess = function(_, text) return text end
	end)

	after_each(function()
		importStub:revert()
		mw.frame.preprocess = originalPreprocess
	end)

	---@param args table
	---@return string
	local function render(args)
		args.schema = 'Example'
		return tostring(ArgSchemaDocumentation.parameters(args))
	end

	it('lists the parameters of the module, by default its `parameters`', function()
		assert.are_equal(
			'<dl><dt><code class="nowrap">&#124;store&#61;false</code></dt><dd>Stores it.</dd></dl>',
			render{}
		)
	end)

	it('lists a section of the module, in the context of the other args', function()
		assert.are_equal('', render{section = 'header', tabletype = 'group'})
		assert.is_truthy(render{section = 'header', tabletype = 'swiss'}:find('&#124;placements&#61;', 1, true))
	end)

	it('errors on a section the module does not declare', function()
		assert.error(function() render{section = 'round'} end)
	end)
end)
