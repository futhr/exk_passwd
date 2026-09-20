# ExkPasswd browser core

This project cooks the canonical ExkPasswd Elixir implementation into the
AtomVM bundle consumed by Futhr's static generator, PWA, and browser extensions.
It is deliberately outside the Hex package file list.

The production bundle uses `ExkPasswd.Random.CryptoSource`, whose only operation
is `:crypto.strong_rand_bytes/1`. Futhr's pinned FissionVM runtime patch backs
that call with the browser's Web Crypto random device. There is no fallback.

Builds are pinned to Popcorn 0.3.3, Elixir 1.17.3, OTP 26.0.2, and the Popcorn
runtime's FissionVM commit `6c3208c7b3dbc7dacc35a19f8de1fa80b358ac73`.

Run the build in the pinned container:

```bash
./scripts/test-core.sh
./scripts/build-core.sh
```

The test command formats and compiles the browser project with warnings as
errors, then runs deterministic protocol conformance tests with the AtomVM
portability branches enabled. The build command verifies that the AVM and its
compressed copy are non-empty and byte-identical after decompression.

The resulting `browser/_release/core/bundle.avm` is an intermediate input to
Futhr's browser-core packaging job. It is never published by the Hex package.

The browser build uses narrow AtomVM portability branches for two unavailable
functions while leaving native behavior intact: equivalent struct construction
replaces `Kernel.struct!/2`, and one-decimal rounding avoids `Float.round/2`.
The browser also explicitly restricts separator and padding pools to ASCII
punctuation because AtomVM does not provide the Unicode regular-expression NIF
used by native validation. Native ExkPasswd continues to accept and validate
Unicode symbols.
