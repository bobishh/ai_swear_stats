# Snowball notices

This app includes the Snowball C runtime and UTF-8 stemmers for English, German, Spanish, French, Italian, Dutch, Polish, Portuguese, and Russian from [Snowball](https://github.com/snowballstem/snowball), pinned to commit [`6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11`](https://github.com/snowballstem/snowball/tree/6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11). The library is licensed under the BSD 3-Clause license. The [upstream license](https://github.com/snowballstem/snowball/blob/6389c79f91cd67ed2de3ebdcf84ec8c2d2d23c11/COPYING) is included in this app as `SNOWBALL-COPYING.txt`.

The project-added C bridge selects a stemmer by explicit language label. No stemmer language detection or word recognition is performed.
