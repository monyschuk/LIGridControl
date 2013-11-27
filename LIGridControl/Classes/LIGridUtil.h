//
//  LIGridUtil.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 11/27/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#ifndef LIGridControl_LIGridUtil_h
#define LIGridControl_LIGridUtil_h

#include <map>
#include <limits>
#include <vector>
#include <algorithm>

#import  "LIGridArea.h"

#define IS_CELL_INDEX(index)     ((index % 2)  > 0)
#define IS_DIVIDER_INDEX(index)  ((index % 2) == 0)

namespace LIGrid {
    namespace Util {
        template <class T>
        class Interval {
        public:
            T start, length;
            
            Interval() : start(0), length(0) {}
            Interval(T val) : start(val), length(0) {}
            Interval(T start, T length) : start(start), length(length) {}
            
            // end value
            
            T end() const {
                return start + length;
            }
            
            // intersection
            bool intersects(const Interval& other) const {
                T minA = start, maxA = start + length;
                T minB = other.start, maxB = other.start + other.length;
                
                return !(minA > maxB || maxA < minB);
            }
            
            // comparison
            bool operator<(const Interval& other) const {
                if (start < other.start) return true;
                if (other.start < start) return false;
                
                return false;
            }
            
            // equality
            bool operator==(const Interval& other) const {
                // don't bother using this with floats...
                return start == other.start && length == other.length;
            }
        };
        
        typedef Interval<CGFloat>       GridSpan;
        typedef std::vector<GridSpan>   GridSpanList;
        
        // Searches a GridSpanList for the span index containing value, using a non-recursive binary search.
        static NSUInteger IndexOfSpanWithLocation(const GridSpanList& list, CGFloat value, BOOL matchNearest = false) {
            size_t len = list.size();
            
            if (len > 0) {
                if (matchNearest) {
                    CGFloat minv = list[0].start;
                    CGFloat maxv = list[len-1].start + list[len-1].length;
                    
                    if (value <= minv) {
                        return 0;
                    } else if (value >= maxv) {
                        return len-1;
                    }
                }
                
                NSInteger imin = 0, imax = len - 1;
                
                while (imax >= imin) {
                    NSInteger  imid = (imin + imax) / 2;
                    
                    CGFloat    minv = list[imid].start;
                    CGFloat    maxv = list[imid].start + list[imid].length;
                    
                    if (value >= minv && value < maxv) {
                        return imid;
                    }
                    else if (value < minv) {
                        imax = imid - 1;
                    }
                    else {
                        imin = imid + 1;
                    }
                }
            }
            
            return NSNotFound;
        }
        
        typedef Interval<NSUInteger>    GridSpanListRange;

        // Fills GridSpanListRanges with row and column spans intersecting rect.
        static void GetGridSpanListRangesWithRect(GridSpanListRange& rowSpanRange, GridSpanListRange& columnSpanRange, const GridSpanList& rowList, const GridSpanList& columnList, NSRect rect) {
            CGFloat minRowValue = NSMinY(rect), maxRowValue = NSMaxY(rect);
            CGFloat minColValue = NSMinX(rect), maxColValue = NSMaxX(rect);
            
            NSUInteger minRowIndex = IndexOfSpanWithLocation(rowList, minRowValue, true);
            NSUInteger maxRowIndex = IndexOfSpanWithLocation(rowList, maxRowValue, true);
            
            NSUInteger minColIndex = IndexOfSpanWithLocation(columnList, minColValue, true);
            NSUInteger maxColIndex = IndexOfSpanWithLocation(columnList, maxColValue, true);
            
            rowSpanRange.start = minRowIndex; rowSpanRange.length = maxRowIndex - minRowIndex;
            columnSpanRange.start = minColIndex; columnSpanRange.length = maxColIndex - minColIndex;
        }
        
        static NSRect RectWithGridSpanListRanges(const GridSpanListRange& rowSpanRange, const GridSpanListRange& columnSpanRange, const GridSpanList& rowList, const GridSpanList& columnList) {
            CGFloat minRowVal = rowList[rowSpanRange.start].start;
            CGFloat maxRowVal = rowList[rowSpanRange.end()].end();
            
            CGFloat minColVal = columnList[columnSpanRange.start].start;
            CGFloat maxColVal = columnList[columnSpanRange.end()].end();
            
            return NSMakeRect(minColVal, minRowVal, maxColVal - minColVal, maxRowVal - minRowVal);
        }
        
        class GridArea {
        public:
            GridSpanListRange rowSpanRange, columnSpanRange;
            
            GridArea() : rowSpanRange(GridSpanListRange()), columnSpanRange(GridSpanListRange()) {}
            GridArea(NSUInteger r, NSUInteger c) : rowSpanRange(GridSpanListRange(r, 1)), columnSpanRange(GridSpanListRange(c, 1)) {}
            GridArea(GridSpanListRange rowRange, GridSpanListRange colRange) : rowSpanRange(rowRange), columnSpanRange(colRange) {}
            
            // intersection
            bool intersects(const GridArea& other) const {
                return rowSpanRange.intersects(other.rowSpanRange) && columnSpanRange.intersects(other.columnSpanRange);
            }
            
            // comparsion
            bool operator<(const GridArea& other) const {
                if (rowSpanRange < other.rowSpanRange) return true;
                if (other.rowSpanRange < rowSpanRange) return false;
                
                if (columnSpanRange < other.columnSpanRange) return true;
                if (other.columnSpanRange < columnSpanRange) return false;
                
                return false;
            }
            
            
            // NOTE: GridArea provides conversion operators allowing you to use them interchangeably with LIGridArea objects.
            // The conversion also converts from cell space to grid space - that's to say that while LIGridArea expresses row
            // and column ranges, GridArea expresses row and column span ranges and conversion between the two objects also
            // converts these spaces.

            
            GridArea(const LIGridArea* coord) {
                // convert from grid space to span space...
                rowSpanRange.start = coord.rowRange.location * 2 + 1; rowSpanRange.length = (coord.rowRange.length > 1) ? coord.rowRange.length * 2 - 1 : coord.rowRange.length;
                columnSpanRange.start = coord.columnRange.location * 2 + 1; columnSpanRange.length = (coord.columnRange.length > 1) ? coord.columnRange.length * 2 - 1 : coord.columnRange.length;
            }
            
            operator LIGridArea*() const {
                // convert from span space to grid space...
                NSRange rr = NSMakeRange((rowSpanRange.start - 1) / 2, (rowSpanRange.length > 1) ? rowSpanRange.length / 2 : rowSpanRange.length);
                NSRange cr = NSMakeRange((columnSpanRange.start - 1) / 2, (columnSpanRange.length > 1) ? columnSpanRange.length / 2 : columnSpanRange.length);
                
                return [LIGridArea areaWithRowRange:rr columnRange:cr representedObject:nil];
            }
        };
        
        typedef std::vector<GridArea> GridAreaList;
        typedef std::map<GridArea, __strong id> GridAreaMap;
    }
}

#endif
