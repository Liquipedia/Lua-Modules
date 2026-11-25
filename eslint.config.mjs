import { defineConfig } from "eslint/config";
import globals from "globals";
import wikimedia from "eslint-config-wikimedia/flat.js";

export default defineConfig([{
    extends: wikimedia( 'mediawiki', 'client/common', 'language/es2024', 'jquery' ),

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
        // TODO: Remove jquery ui uses entirely then remove this override
        "no-jquery/no-jquery-ui": "warn",
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
        "compat/compat": [
            "error",
            "> 0.5% and baseline widely available"
        ],

        "jsdoc/check-tag-names": ["error", {
            definedTags: ["jest-environment"],
        }],

        "max-len": ["warn", {
            code: 120,
        }],
    },
}]);
