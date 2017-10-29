--- src/bootstrap/bootstrap.py.orig	2017-07-22 08:10:52 UTC
+++ src/bootstrap/bootstrap.py
@@ -400,7 +400,7 @@ class RustBuild(object):
             os.pathsep + env["PATH"]
         if not os.path.isfile(self.cargo()):
             raise Exception("no cargo executable found at `%s`" % self.cargo())
-        args = [self.cargo(), "build", "--manifest-path",
+        args = [self.cargo(), "build", "--jobs", "1", "--manifest-path",
                 os.path.join(self.rust_root, "src/bootstrap/Cargo.toml")]
         if self.verbose:
             args.append("--verbose")
