--- src/bootstrap/bootstrap.py.orig	2017-10-09 20:04:51 UTC
+++ src/bootstrap/bootstrap.py
@@ -503,7 +503,7 @@ class RustBuild(object):
         if not os.path.isfile(self.cargo()):
             raise Exception("no cargo executable found at `{}`".format(
                 self.cargo()))
-        args = [self.cargo(), "build", "--manifest-path",
+        args = [self.cargo(), "build", "--jobs", "1", "--manifest-path",
                 os.path.join(self.rust_root, "src/bootstrap/Cargo.toml")]
         if self.verbose:
             args.append("--verbose")
