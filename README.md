LIGridControl
=============

An efficient variable-sized grid of NSCells. LIGridControl supports Mac OS 10.9 Mavericks and later. To use LIGridControl, import the contents of the **Classes** folder into your own project. To see a sample of LIGridControl usage, open LIGridControl.xcodeproj and run the sample application which draws a custom grid.

Features
--------

LIGridControl is an alternative to NSTableView that provides more efficient support for variable sized rows and columns, extensive support for grid layout and styling, and keyboard control familiar to spreadsheet users.

Classes
-------

LIGridControl contains both Objective C and C++ classes. The C++ implementation serves as a kernel of sorts for layout logic and has been separated from the Objective C portion so that it can be reused in an iOS implementation of the grid. The Mac version of LIGridControl is implemented using the NSController-NSCell system for best performance while a future iOS implementation will use layers.

C++ classes in the project live in the **li::** namespace and include:

- **geom::point** and **geom::rect** - CGPoint and CGRect-like classes which are interchangeable with their CG... equivalent structures, but which add logic like intersection, union, and containment tests.

- **grid::span** - Span represents the starting point and size of a row, column, row divider, or column divider. Grid layouts are, effectively, arrays of spans for the row (y) and column (x) axes.

- **grid::interval** - represents a range of cells or spans along the row or column axis. The interval class provides functions to convert between cell intervals and span intervals.

- **grid::area** - Area represents a grid cell area: either a single (row, column) pair, or a range of rows and columns. Areas use interval objects to represent ranges of rows and columns and express their ranges in terms of cells rather than spans. for N cells along either the row or column axis, 2N + 1 spans exist: 

		div(0) : cell(0) : div(1) : cell(1) ... div(N) : cell(N) : div(N+1)

- **grid::grid** - a grid layout which stores row, column, and divider sizes. grid also stores fixed grid areas to represent cells that have been joined together and that are tagged with associated Objective C objects. grid is our layout kernel.

Objective C classes in the project implemenet grid visuals and event handling:

- **LIGridControl** - a grid of cells and dividers. In a spreadsheet style layout, LIGridControl is used to represent both the spreadsheet proper and its associated row and column headers. LIGridControl defines both a data source and delegate protocol used to populate grid data and modify how that data is displayed within the grid.

- **LIGridArea** - a cell area that corresponds either to a single row:column pair, or to a range of rows and columns and an associated Objective C object if the area is fixed. 

- **LISelectionArea** - a subclass of LIGridArea used to represent grid selection. Grids can have multiply-selected cells and ranges of cells. LISelectionArea represents each distinct selection in the control, and has methods used to extend selection or to move it. Selection in grids whose cells are all single row:column pairs is a pretty simple matter; but grids with cells that span multiple rows and columns complicate selection logic. LISelectionArea encapsulates and abstracts this complication.

- **LIGridFieldCell**, **LIGridDividerCell** - cells used to display grid cell data and dividers. If you want to change the look of LIGridControl, these are the classes you need to work with or possibly subclass. Associated NSControls for each are included in the project mostly as a convenience - you may want to display a cell or divider outside of a grid (in an inspector, for example) and these controls are how you do it. 

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
