/** @type {import("stylelint").Config} */
export default {
	"extends": [
		"stylelint-config-wikimedia"
	],
	"plugins": [
		"stylelint-scss"
	],
	"customSyntax": "postcss-scss",
	"rules": {
		"at-rule-no-unknown": null,
		"scss/at-rule-no-unknown": true,
		"color-hex-length": "long",
		"font-family-no-missing-generic-family-keyword": [
			true,
			{
				"ignoreFontFamilies": ["/^Font Awesome/"]
			}
		],
		"unit-disallowed-list": null,
		"declaration-property-unit-disallowed-list": {},
		"no-descending-specificity": null,
		"selector-max-id": null,
		"no-duplicate-selectors": null,
		"function-url-no-scheme-relative": null,
		"declaration-no-important": null,
		"function-no-unknown": null,
		"scss/function-no-unknown": true,
		"@stylistic/string-quotes": "double"
	}
};
