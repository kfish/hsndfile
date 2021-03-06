### Version 0.5

* [__USER__] Remove lazy read functions `hGetContentChunks` and `readFileChunks` from library interface. Those functions were implemented incorrectly.

### Version 0.4

* [__USER__] Simplified Buffer API: A single type class, **Buffer**, is provided for **ForeignPtr** based I/O. Instances are provided in separate packages, e.g. [hsndfile-vector](http://hackage.haskell.org/package/hsndfile-vector).

### Version 0.3.2

* [__USER__] **hsndfile** has been adapted to compile with GHC 6.10. The only
  visible change is in exception handling:
    * `Sound.File.Sndfile.Exception.Exception` is now an instance of
      `Control.Exception.Exception`
    * The new generalized functions from `Control.Exception.Exception` are
      used for throwing and handling exceptions

### Version 0.2.0

* [__BUGFIX__] Fix exception throwing Exceptions detected in library code are
  now actually raised. Exception has been factored into
  Sound.File.Sndfile.Exception and constructors were added according to the
  public libsndfile error codes.
* [__BUGFIX__] Fix reading/writing of frames hGetFrames and hPutFrames were
  using the sample-based library functions. These have been factored into
  Sound.File.Sndfile.Buffer and the correct functions are being used for the
  frame-based I/O functions.
