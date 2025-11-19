# Changelog

All notable changes to exk_passwd will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Cryptographically secure password generation using `:crypto.strong_rand_bytes/1`
- EFF Large Wordlist (7,776 words, 12.9 bits entropy per word)
- 7 built-in presets: default, xkcd, web32, web16, wifi, apple_id, security
- Custom dictionary support via ETS
- Batch and parallel password generation
- Entropy calculation (blind and seen)
- Strength analysis and feedback
- Case transformations: none, alternate, capitalize, invert, lower, upper, random
- Character substitutions (leetspeak)
- Pinyin transform with 500+ characters (Jun Da frequency list)
- Romaji transform with IME-grade Modified Hepburn romanization
- Helper functions: `contains_hanzi?/1`, `hanzi?/1`, `contains_kanji?/1`, `kanji?/1`
- Comprehensive documentation and Livebook notebooks
- 98% test coverage
- Zero runtime dependencies

[Unreleased]: https://github.com/futhr/exk_passwd/compare/main...HEAD
