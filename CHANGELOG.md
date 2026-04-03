# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v0.1.1](https://github.com/futhr/exk_passwd/compare/v0.1.0...v0.1.1) (2026-04-03)




### Bug Fixes:

* trim hex package description and exclude PLT files by Tobias Bohwalli

* raise memory leak test threshold for CI environments by Tobias Bohwalli

* disable async tests that use shared ETS state by Tobias Bohwalli

## [v0.1.2](https://github.com/futhr/exk_passwd/compare/v0.1.1...v0.1.2) (2026-04-03)




### Bug Fixes:

* trim hex package description and exclude PLT files by Tobias Bohwalli

* raise memory leak test threshold for CI environments by Tobias Bohwalli

* disable async tests that use shared ETS state by Tobias Bohwalli

## [v0.1.0](https://github.com/futhr/exk_passwd/compare/v0.1.0...v0.1.0) (2026-04-03)

### Features:

* bench: generate markdown benchmark reports by Tobias Bohwalli

* validator: add run_all/2 function for testable validation by Tobias Bohwalli

* expand Pinyin transform with 500+ characters and helpers by Tobias Bohwalli

* improve config schema validation for Unicode symbols by Tobias Bohwalli

* Use GitHub as source instead of HEX (which doesn't yet exist). by Michael Westbay

* Add # character to allowed symbols. by Michael Westbay

* Suppress consolidate_protocol warnings in dev environment. by Michael Westbay

* add internationalization support for Chinese and Japanese by Tobias Bohwalli

* implement core password generation library by Tobias Bohwalli

* add word dictionaries for password generation by Tobias Bohwalli

### Bug Fixes:

* prepare README for hex release by Tobias Bohwalli

* test: use anonymous unused variables in test files by Tobias Bohwalli

* credo: enable UnusedVariableNames with force: :anonymous by Tobias Bohwalli

* test: resolve credo strict violations in test files by Tobias Bohwalli

* config: suppress false-positive AppendSingleItem credo warnings by Tobias Bohwalli

* transform: add @spec to protocol implementation functions by Tobias Bohwalli

* dictionary: use try/rescue for ETS table init by Tobias Bohwalli

* disable ex_unit to prevent duplicate test runs in mix check by Tobias Bohwalli

* version doctest to not break on bump by Tobias Bohwalli

* Get livebook examples to all work properly. by Michael Westbay

* Change invalid symbol from # which is now valid. by Michael Westbay

* Change invalid separator from # which is now valid. by Michael Westbay

* Change invalid padding character from # which is now valid. by Michael Westbay

* Calculate word entropy for custom dictionaries. by Michael Westbay

* Merge configuring padding with default padding. by Michael Westbay

* Handle case when {min, max} range not in customer dictionary. by Michael Westbay

* update CI badge to match renamed workflow by Tobias Bohwalli

* simplify CI coverage check to parse test output directly by Tobias Bohwalli

* increase threshold for flaky sequential digit pattern test by Tobias Bohwalli

* remove failing benchmark action that expected JSON format by Tobias Bohwalli

* resolve CI test failures and documentation issues by Tobias Bohwalli

### Performance Improvements:

* add benchmarks and livebook examples by Tobias Bohwalli
