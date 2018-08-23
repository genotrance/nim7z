Nim7z is a [Nim](https://nim-lang.org/) wrapper for the [7zip decoder](https://github.com/kornelski/7z).

Nim7z is distributed as a [Nimble](https://github.com/nim-lang/nimble) package and depends on [nimgen](https://github.com/genotrance/nimgen) and [c2nim](https://github.com/nim-lang/c2nim/) to generate the wrappers. The 7zip source code is downloaded using Git so having ```git``` in the path is required.

__Installation__

Nim7z can be installed via [Nimble](https://github.com/nim-lang/nimble):

```
> nimble install nim7z
```

This will download, wrap and install nim7z in the standard Nimble package location, typically ~/.nimble. Once installed, it can be imported into any Nim program.

__Usage__

Module documentation can be found [here](http://nimgen.genotrance.com/nim7z).

```nim
import nim7z

let svnz = new7zFile("testfile.7z")
extract(svnz, "outdir")

extract("testfile.7z", "outdir", skipOuterDirs=true)
```

Refer to the ```tests``` directory for examples on how the library can be used.

__Credits__

Nim7z wraps the 7zip source code and all licensing terms of [7zip](https://github.com/kornelski/7z) apply to the usage of this package.

Credits go out to [c2nim](https://github.com/nim-lang/c2nim/) as well without which this package would be greatly limited in its abilities.

__Feedback__

Nim7z is a work in progress and any feedback or suggestions are welcome. It is hosted on [GitHub](https://github.com/genotrance/nim7z) with an MIT license so issues, forks and PRs are most appreciated.
