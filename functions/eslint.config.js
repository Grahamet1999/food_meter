module.exports = [
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
    },
    rules: {
      quotes: ["error", "double"],
      indent: ["error", 2],
      "no-unused-vars": "error",
      "max-len": ["error", { code: 100 }],
      // Add more rules as needed
    },
    ignores: ["node_modules/"],
  },
];