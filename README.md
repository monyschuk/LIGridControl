LIGridControl
=============

An efficient variable-sized grid of NSCells. LIGridControl supports Mac OS 10.9 and later. To use LIGridControl, import the contents of the **Classes** folder into your own project. To see a sample of LIGridControl usage, open LIGridControl.xcodeproj and run the sample application which draws a custom grid.

Features
--------

LIGridControl is an alternative to NSTableView that provides more efficient support for variable sized rows and columns, extensive support for grid layout and styling, and keyboard control familiar to spreadsheet users.

Classes
-------

[TBD]

Key Event Handling
------------------

LIGridControl defines a block property executed on keyDown: and assigns a default implementation of the block consistent with typical spreadsheet key handling.

The block initiates editing if an alphanumeric or punctuation character is keyed. If the '=' sign is keyed, then a new optional responder method **insertFunction:** is passed through the responder chain.

At time of writing, the block is implemented like so:

    __weak LIGridControl *weakSelf = self;
    _keyDownHandler = ^BOOL(NSEvent *keyEvent) {
        if ([keyEvent.characters isEqualToString:@"="]) {
            [weakSelf doCommandBySelector:@selector(insertFunction:)];
            return YES;
            
        } else {
            NSMutableCharacterSet *editChars = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
            [editChars formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
            
            if (weakSelf.selectedArea != nil) {
                if ([[keyEvent characters] rangeOfCharacterFromSet:editChars].location != NSNotFound) {
                    [weakSelf editGridArea:weakSelf.selectedArea];
                    [weakSelf.currentEditor insertText:keyEvent.characters];
                    
                    return YES;
                }
            }
        }
        
        return NO;
    };

Please refer to LIGridControl.mm for the most recent implementation of the key handler block.

License & Notes
---------------

LIGridControl is licensed under the MIT license and hosted on GitHub at https://github.com/monyschuk/LIGridControl/. Fork the project and feel free to send pull requests with your changes!


TODO
----

* collapsed row and column support
* header styled subclass of LIGridFieldCell
* row and column divider dragging and related delegate methods
