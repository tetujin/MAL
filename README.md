# MAL

## Overview
**MAL** is an application logger for Mac OS X. 
This application can detect following actions: _current using application_, _mouse and keyboard_, and _PC's active state (ON/OFF)_. Also, each detected actions are saved as a CSV file at user's home directory. If you will customize source code, you can upload those actions to the server. 

## How to use MAL.app ?
- Download the source file from "Download ZIP" button.
- Open `MAL.app` in the file by double click, and then an application window will be appeared. 
-- If the window is not aooeared, you should check a security setting of your computer (from `System Preferences -> Security&Privacy -> General`.)
-- If you want to detect keyboard actions, you have to permit access to the keyboard API (from `System Preferences -> Security&Privacy -> Privacy -> Accessibility -> "Check MAL.zpp"`.)
- Detected actions are saved as CSV files, with timestamp (unixtime).

|Type of Actions|File Name (Defulat)|
|---|---|
|PC's active state|~/mal-pcstate.csv|
|Current using application|~/mal-app.csv|
|Keyboard action|~/mal-key.csv|
|Mouse action|~/mal-mouse.csv|

- You can check MAL's action using a following command.
```
$ tail -f ~/mal-app.csv
```


## How to customize MAL.app ?
... coming soon


## License
The MIT License (MIT)

Copyright (c) 2015 Yuuki NISHIYAMA

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
