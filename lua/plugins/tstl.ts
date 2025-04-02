import { SourceNode } from 'source-map';
import ts from 'typescript';
import * as tstl from 'typescript-to-lua';

const WIKIS_DIR = '/lua/wikis/';
const LUA_IMPORTS = `local Lua = require('Module:Lua')\nlocal WidgetFactory = Lua.import('Module:Widget/Factory')\n`;
const LUALIB_BUNDLE = 'lualib_bundle';
const LUALIB_BUNDLE_WIKI = `Module:TSTL/LuaLibBundle`;

class CustomPrinter extends tstl.LuaPrinter {
	printCallExpression(expression: tstl.CallExpression): SourceNode {
		if (
			expression.expression.kind === tstl.SyntaxKind.Identifier &&
			expression.params[0] &&
			expression.params[0].kind === tstl.SyntaxKind.StringLiteral
		) {
			const identifier = expression.expression as tstl.Identifier;
			const firstParam = expression.params[0] as tstl.StringLiteral;
			const moduleName = firstParam.value;

			// We have to do the LuaLibBundle later on
			if (identifier.text == 'require' && moduleName !== LUALIB_BUNDLE) {
				identifier.text = 'Lua.import';
				/* a path looks like "commons/Foo/Bar" and we want to convert that to "Module:Foo/Bar" */
				firstParam.value =
					'Module:' + moduleName.slice(Math.max(0, moduleName.indexOf('/') + 1));
			}
		}
		return super.printCallExpression(expression);
	}
}

const plugin: tstl.Plugin = {
	printer: (program: ts.Program, emitHost: tstl.EmitHost, fileName: string, file: tstl.File) => {
		return new CustomPrinter(emitHost, program, fileName).print(file);
	},

	beforeEmit(
		program: ts.Program,
		options: tstl.CompilerOptions,
		emitHost: tstl.EmitHost,
		result: tstl.EmitFile[]
	) {
		for (const file of result) {
			const isLuaLib = file.outputPath.indexOf(LUALIB_BUNDLE) !== -1;
			// Add deploy header
			const relativePath = file.outputPath.substring(
				file.outputPath.indexOf(WIKIS_DIR) + WIKIS_DIR.length
			);

			let wiki: string, moduleName: string;
			if (isLuaLib) {
				wiki = 'commons';
				moduleName = LUALIB_BUNDLE_WIKI;
			} else {
				let moduleParts: string[];
				[wiki, ...moduleParts] = relativePath.split('/');
				moduleName = moduleParts.join('/').replace('.tsx', '').replace('.ts', '');
			}

			const LUA_MAGIC = `---
-- @Liquipedia
-- wiki=${wiki}
-- page=Module:${moduleName}
--
-- ${isLuaLib ? 'Generated by TSTL' : `Source can be found at https://github.com/Liquipedia/Lua-Modules/blob/main${WIKIS_DIR}${relativePath}`}
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--`;
			file.code = `${LUA_MAGIC}\n${LUA_IMPORTS}\n${file.code}`;

			if (!isLuaLib) {
				// Replace TSTL Lua Lib require with our own
				// We cannot do this in the printer because post printer TSTL checks if any require is lualib_bundle
				file.code = file.code.replace(
					`require("${LUALIB_BUNDLE}")`,
					`Lua.import("${LUALIB_BUNDLE_WIKI}")`
				);
			} else {
				// TODO: Move to a dir that is deployed
				console.log(file.outputPath);
			}
		}
	},
};

export default plugin;
