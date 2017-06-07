// RUN: rm -rf %t && mkdir -p %t

// RUN: %swiftc_driver -typecheck -driver-print-actions -import-objc-header %S/Inputs/bridging-header.h %s 2>&1 | %FileCheck %s -check-prefix=YESPCHACT
// YESPCHACT: 0: input, "{{.*}}Inputs/bridging-header.h", objc-header
// YESPCHACT: 1: generate-pch, {0}, pch
// YESPCHACT: 2: input, "{{.*}}bridging-pch.swift", swift
// YESPCHACT: 3: compile, {2, 1}, none

// RUN: %swiftc_driver -typecheck -disable-bridging-pch -driver-print-actions -import-objc-header %S/Inputs/bridging-header.h %s 2>&1 | %FileCheck %s -check-prefix=NOPCHACT
// NOPCHACT: 0: input, "{{.*}}bridging-pch.swift", swift
// NOPCHACT: 1: compile, {0}, none

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h %s 2>&1 | %FileCheck %s -check-prefix=YESPCHJOB
// YESPCHJOB: {{.*}}swift -frontend {{.*}} -emit-pch -o {{.*}}bridging-header-{{.*}}.pch
// YESPCHJOB: {{.*}}swift -frontend {{.*}} -import-objc-header {{.*}}bridging-header-{{.*}}.pch

// RUN: %swiftc_driver -typecheck -disable-bridging-pch  -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h %s 2>&1 | %FileCheck %s -check-prefix=NOPCHJOB
// NOPCHJOB: {{.*}}swift -frontend {{.*}} -import-objc-header {{.*}}Inputs/bridging-header.h

// RUN: echo "{\"\": {\"swift-dependencies\": \"master.swiftdeps\"}}" > %t.json
// RUN: %swiftc_driver -typecheck -incremental -enable-bridging-pch -output-file-map %t.json -import-objc-header %S/Inputs/bridging-header.h %s

// RUN: mkdir %t/tmp
// RUN: not env TMPDIR="%t/tmp/" %swiftc_driver -typecheck -import-objc-header %S/../Inputs/empty.h -driver-use-frontend-path %S/Inputs/crash-after-generating-pch.py %s
// RUN: ls %t/tmp/*.pch

// Test persistent PCH

// RUN: %swiftc_driver -typecheck -driver-print-actions -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-YESPCHACT
// PERSISTENT-YESPCHACT: 0: input, "{{.*}}Inputs/bridging-header.h", objc-header
// PERSISTENT-YESPCHACT: 1: generate-pch, {0}, none
// PERSISTENT-YESPCHACT: 2: input, "{{.*}}bridging-pch.swift", swift
// PERSISTENT-YESPCHACT: 3: compile, {2, 1}, none

// RUN: %swiftc_driver -typecheck -disable-bridging-pch -driver-print-actions -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch %s 2>&1 | %FileCheck %s -check-prefix=NOPCHACT

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch -disable-bridging-pch %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-DISABLED-YESPCHJOB
// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch -whole-module-optimization -disable-bridging-pch %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-DISABLED-YESPCHJOB
// PERSISTENT-DISABLED-YESPCHJOB-NOT: -pch-output-dir

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-YESPCHJOB
// PERSISTENT-YESPCHJOB: {{.*}}swift -frontend {{.*}} -emit-pch -pch-output-dir {{.*}}/pch
// PERSISTENT-YESPCHJOB: {{.*}}swift -frontend {{.*}} -import-objc-header {{.*}}bridging-header.h -pch-output-dir {{.*}}/pch -pch-disable-validation

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch -serialize-diagnostics %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-YESPCHJOB-DIAG1
// PERSISTENT-YESPCHJOB-DIAG1: {{.*}}swift -frontend {{.*}} -serialize-diagnostics-path {{.*}}bridging-header-{{.*}}.dia {{.*}} -emit-pch -pch-output-dir {{.*}}/pch

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch-out-dir -serialize-diagnostics %s -emit-module -emit-module-path /module-path-dir 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-YESPCHJOB-DIAG2
// PERSISTENT-YESPCHJOB-DIAG2: {{.*}}swift -frontend {{.*}} -serialize-diagnostics-path {{.*}}/pch-out-dir/bridging-header-{{.*}}.dia {{.*}} -emit-pch -pch-output-dir {{.*}}/pch-out-dir

// RUN: %swiftc_driver -typecheck -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch -parseable-output -driver-skip-execution %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-OUTPUT
// PERSISTENT-OUTPUT-NOT: "outputs": [

// RUN: %swiftc_driver -typecheck -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch -whole-module-optimization %s 2>&1 | %FileCheck %s -check-prefix=PERSISTENT-WMO-YESPCHJOB --implicit-check-not pch-disable-validation
// PERSISTENT-WMO-YESPCHJOB: {{.*}}swift -frontend {{.*}} -import-objc-header {{.*}}bridging-header.h -pch-output-dir {{.*}}/pch

// RUN: %swiftc_driver -typecheck -disable-bridging-pch  -driver-print-jobs -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch %s 2>&1 | %FileCheck %s -check-prefix=NOPCHJOB
// RUN: %swiftc_driver -typecheck -incremental -enable-bridging-pch -output-file-map %t.json -import-objc-header %S/Inputs/bridging-header.h -pch-output-dir %t/pch %s
