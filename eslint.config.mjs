import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
	eslint.configs.recommended,
	tseslint.configs.recommended,
	tseslint.configs.strict,
	tseslint.configs.stylistic,
	tseslint.configs.recommendedTypeChecked,
	{
		languageOptions: {
			parserOptions: {
				projectService: true,
				project: "./tsconfig.json",
				tsconfigRootDir: import.meta.dirname,
			},
		},
	},
	{
		rules: {
			"@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
			"@typescript-eslint/strict-boolean-expressions": "error",
			"no-restricted-imports": ["error", {
				patterns: [{
					group: ["./*", "../*"],
					message: "Relative imports are not allowed."
				}]
			}],
			"eqeqeq": ["error", "always"]
		},
	},
	{
		ignores: ["**/plugins/*", "**/eslint.config.mjs"],
	},
);
