import { defineConfig } from "eslint/config";
import globals from "globals";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const compat = new FlatCompat({
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default defineConfig([{
    extends: compat.extends(
        "wikimedia/mediawiki",
        "wikimedia/client/common",
        "wikimedia/language/es2020",
        "wikimedia/jquery",
    ),

    files: ["javascript/**/*.js"],

    languageOptions: {
        globals: {
            ...globals.jquery,
            liquipedia: "readonly",
            echarts: "readonly",
            _paq: "readonly",
            gtag: "readonly",
            Share: "readonly",
        },
    },

    rules: {
        "space-before-function-paren": "off",
        "no-jquery/no-global-selector": "off",
        "vars-on-top": "off",
        "one-var": "off",
        "es/no-array-from": "off",
        "mediawiki/class-doc": "off",
        "mediawiki/no-nodelist-unsupported-methods": "off",
        "mediawiki/no-unlabeled-buttonwidget": "off",
        "es-x/no-block-scoped-variables": "off",
        "es-x/no-string-prototype-startswith": "off",
        "es-x/no-string-prototype-includes": "off",
        "es-x/no-array-prototype-includes": "off",
        "es-x/no-array-prototype-findindex": "off",
        "es-x/no-spread-elements": "off",
        "es-x/no-property-shorthands": "off",

        "jsdoc/check-tag-names": ["error", {
            definedTags: ["jest-environment"],
        }],

        "max-len": ["warn", {
            code: 120,
        }],
    },
}]);
