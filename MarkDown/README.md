# Usage
With this you get 2 different outputs

- MarkDown
- MarkDown_GitHub

Both of these return the same output structure, however MarkDown_GitHub will not include the directory of the file to link to, as currently github wiki does not support directories in their wiki 
links.
```
/path/to/NaturalDocs -i /path/to/my/project -o MarkDown /path/to/output/folder -p /path/to/naturaldocs/project
```

# Install
## Download this repo
## Copy all files from MarkDown to
```
cp * /path/to/NaturalDocs/Modules/NaturalDocs/Builder/
```
## Edit /path/to/NaturalDocs/Modules/NaturalDocs/Builder.pm
```
use strict;
use integer;

use NaturalDocs::Builder::Base;
use NaturalDocs::Builder::HTML;
use NaturalDocs::Builder::FramedHTML;
use NaturalDocs::Builder::MarkDown;        # Add this line
use NaturalDocs::Builder::MarkDown_GitHub; # Add this line

package NaturalDocs::Builder;
```
## Try it out
```
/path/to/NaturalDocs -i /path/to/my/project -o MarkDown /path/to/output/folder -p /path/to/naturaldocs/project
```

# Known Issues
- Not all NaturalDocs markup is supported atm.
- more probably

# Todo
1. Complete NDMarkup support
2. Clean up code
3. Make a Home.md file with an outline of all the files
4. Clean up code
