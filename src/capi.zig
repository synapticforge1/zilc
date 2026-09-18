// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! The C ABI of the zilc runtime — the contract declared in `include/zilc.h`.
//! Every symbol here must have a matching declaration there, and vice versa.

const zilc = @import("zilc");

/// Returns the zilc version as a NUL-terminated static string.
export fn zilc_version() [*:0]const u8 {
    return zilc.version_string;
}
