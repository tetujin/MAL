# MAL

## Overview
**MAL** is an application logger for Mac OS X. 
This application detects following actions: _current using application_, _mouse and keyboard_, and _PC's active state (ON/OFF)_. Also, each detected action was saved to log files. If you will modify source code, you can upload those actions to the server. 

## How to use MAL.app
- Download the source file from "Download ZIP" button.
- Double click the `MAL.app`. (If the App is not opened, you should check security of App from `System Preferences -> Security&Privacy -> General`.)
- The aplication window will be popup.
- Detected actions were save to each log-files, with timestamp (unixtime).

|Type of actions|File Name (Defulat Setting)|
|---|---|
|PC's active state|~/.mal.log|
|Current using application|~/.mal.app.log|
|Keyboard action|~/.mal.key.log|
|Mouse action|~/.mal.mouse.log|


## License
The MIT License (MIT)

Copyright (c) 2015 Yuuki NISHIYAMA

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
