/// Test diagnostics with module aliasing.
///
/// Module 'Lib' imports module 'XLogging', and 'XLogging' is aliased 'AppleLogging'.

// RUN: %empty-directory(%t)
// RUN: %{python} %utils/split_file.py -o %t %s

/// Create AppleLogging.swiftmodule by aliasing XLogging
// RUN: %target-swift-frontend -module-name AppleLogging -module-alias XLogging=AppleLogging %t/FileLogging.swift -emit-module -emit-module-path %t/AppleLogging.swiftmodule
// RUN: test -f %t/AppleLogging.swiftmodule

/// 1. Pass: load and reference a module with module aliasing
/// Create module Lib that imports XLogging WITH -module-alias XLogging=AppleLogging
// RUN: %target-swift-frontend -module-name LibA %t/FileLib.swift -module-alias XLogging=AppleLogging -I %t -emit-module -emit-module-path %t/LibA.swiftmodule -Rmodule-loading 2> %t/result-LibA.output
// RUN: test -f %t/LibA.swiftmodule
// RUN: %FileCheck %s -input-file %t/result-LibA.output -check-prefix CHECK-LOAD
// CHECK-LOAD: remark: loaded module at {{.*}}AppleLogging.swiftmodule

/// 2. Fail: trying to access a non-member of a module (with module aliasing) should fail with the module alias in the diags
/// Try building module Lib that imports XLogging WITH -module-alias XLogging=AppleLogging
// RUN: not %target-swift-frontend -module-name LibB %t/FileLibNoSuchMember.swift -module-alias XLogging=AppleLogging -I %t -emit-module -emit-module-path %t/LibB.swiftmodule 2> %t/result-LibB.output
// RUN: %FileCheck %s -input-file %t/result-LibB.output -check-prefix CHECK-NO-MEMBER
// CHECK-NO-MEMBER: error: module 'XLogging' has no member named 'setupErr'

/// 3. Fail: referencing the real module name that's aliased should fail
/// Create module Lib that imports XLogging WITH -module-alias XLogging=AppleLogging
// RUN: not %target-swift-frontend -module-name LibC %t/FileLibRefRealName.swift -module-alias XLogging=AppleLogging -I %t -emit-module -emit-module-path %t/LibC.swiftmodule 2> %t/result-LibC.output
// RUN: %FileCheck %s -input-file %t/result-LibC.output -check-prefix CHECK-NOT-REF
// CHECK-NOT-REF: error: cannot find 'AppleLogging' in scope

/// 4. Fail: importing the real module name that's being aliased should fail
/// Create module Lib that imports XLogging WITH -module-alias XLogging=AppleLogging
// RUN: not %target-swift-frontend -module-name LibC %t/FileLibImportRealName.swift -module-alias XLogging=AppleLogging -I %t -emit-module -emit-module-path %t/LibC.swiftmodule 2> %t/result-LibC.output
// RUN: %FileCheck %s -input-file %t/result-LibC.output -check-prefix CHECK-NOT-IMPORT
// CHECK-NOT-IMPORT: error: no such module 'AppleLogging'

// BEGIN FileLogging.swift
public struct Logger {
  public init() {}
}

public func setup() -> XLogging.Logger? {
  return Logger()
}

// BEGIN FileLib.swift
import XLogging

public func start() {
  _ = XLogging.setup()
}

// BEGIN FileLibNoSuchMember.swift
import XLogging

public func start() {
  _ = XLogging.setupErr()
}

// BEGIN FileLibRefRealName.swift
import XLogging

public func start() {
  _ = AppleLogging.setup()
}

// BEGIN FileLibImportRealName.swift
import XLogging
import AppleLogging

public func start() {
  _ = XLogging.setup()
}

