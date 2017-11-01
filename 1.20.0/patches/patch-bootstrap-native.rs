--- src/bootstrap/native.rs.orig	2017-06-27 08:57:03.339167000 +0200
+++ src/bootstrap/native.rs	2017-06-27 08:57:20.059627000 +0200
@@ -295,6 +295,7 @@
         "x86_64-unknown-linux-gnu" => "linux-x86_64",
         "x86_64-unknown-linux-musl" => "linux-x86_64",
         "x86_64-unknown-netbsd" => "BSD-x86_64",
+        "x86_64-unknown-dragonfly" => "BSD-x86_64",
         _ => panic!("don't know how to configure OpenSSL for {}", target),
     };
     configure.arg(os);
