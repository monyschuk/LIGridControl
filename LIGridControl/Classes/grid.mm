//
//  grid.cpp
//  LIGridControl
//
//  Created by Mark Onyschuk on 12/3/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#include "grid.h"

using namespace li::grid;
using namespace li::geom;

void grid::clear() {
    rows.clear();
    cols.clear();
    fixed.clear();
}

// returns true if either the grids row or column spans are empty

bool grid::empty() const {
    return rows.empty() || cols.empty();
}

void grid::reserve_rows(size_t nrows) {
    rows.reserve(nrows*2 + 1);
}
void grid::reserve_cols(size_t ncols) {
    cols.reserve(ncols*2 + 1);
}

// returns true if index is a cell span index

static inline bool is_cell(unsigned long index) {
    return (index % 2) != 0;
}

// returns true if index is a divider span index

static inline bool is_divider(unsigned long index) {
    return (index % 2) == 0;
}

// pushes a cell span of length size onto a span list.
// if the list position is meant to hold a divider span, then
// a zero-length divider is added prior to adding the cell span.

static void push_cell(span_list& spans, float size) {
    const float max = spans.back().get_end();
    
    if (!is_cell(spans.size())) {
        spans.push_back(span(max));
    }
    
    spans.push_back(span(max, size));
}

// pushes a divider span of length size onto a span list.
// if the list position is meant to hold a cell span, then
// a zero-length cell is added prior to adding the divider span.

static void push_divider(span_list& spans, float size) {
    const float max = spans.back().get_end();
    
    if (!is_divider(spans.size())) {
        spans.push_back(span(max, 0));
    }
    
    spans.push_back(span(max, size));
}

// pushes a row of height size onto the row span list

void grid::push_row(float size) {
    push_cell(rows, size);
}

// pushes a column of width size onto the column span list

void grid::push_col(float size) {
    push_cell(cols, size);
}

// pushes a row divider of height onto the row span list

void grid::push_row_divider(float size) {
    push_divider(rows, size);
}

// pushes a column divider of width onto the column span list

void grid::push_col_divider(float size) {
    push_divider(cols, size);
}

// pushes a fixed area of rows and columns, associated with obj, into the fixed area map

void grid::push_fixed(const area& area, __strong id obj) {
    fixed[area] = obj;
}

// returns true if value exists within the given span list, and populates index with the index of
// the span that contains value. if match_nearest is true then the nearest matching index is returned.

static bool get_span_index(size_t& index, const span_list& spans, const double value, bool match_nearest = false) {
    size_t len = spans.size();
    
    if (len > 0) {
        if (match_nearest) {
            CGFloat minv = spans[0].start;
            CGFloat maxv = spans[len-1].start + spans[len-1].length;
            
            if (value <= minv) {
                index = 0;
                return true;
            } else if (value >= maxv) {
                index = len-1;
                return true;
            }
        }
        
        size_t imin = 0, imax = len - 1;
        
        while (imax >= imin) {
            size_t  imid = (imin + imax) / 2;
            
            double  minv = spans[imid].start;
            double  maxv = spans[imid].start + spans[imid].length;
            
            if (value >= minv && value < maxv) {
                index = imid;
                return true;
            }
            else if (value < minv) {
                imax = imid - 1;
            }
            else {
                imin = imid + 1;
            }
        }
    }
    
    return false;
}

bool grid::get_fixed_areas(std::vector<area>& fixed_areas, std::vector<__strong id>& fixed_objs, const range& cell_row_range, const range& cell_column_range) {
    bool found = false;
    
    for (auto pair : fixed) {
        if (pair.first.rows.intersects(cell_row_range) && pair.first.cols.intersects(cell_column_range)) {
            fixed_areas.push_back(pair.first);
            fixed_objs.push_back(pair.second);
            
            found = true;
        }
    }
    
    return found;
}

rect grid::get_area_rect(const area& cell_area) const {
    size_t minr = cell_area.rows.start;
    size_t minc = cell_area.cols.start;
    
    size_t maxr = cell_area.rows.get_end(); if (maxr > minr) maxr -= 1;
    size_t maxc = cell_area.cols.get_end(); if (maxc > minc) maxc -= 1;

    rect   minrect = get_area_rect(minr, minc);
    rect   maxrect = get_area_rect(maxr, maxc);
    
    return minrect.union_rect(maxrect);
}

rect grid::get_area_rect(const size_t& row, const size_t& col) const {
    range row_range((row*2)+1, 0);
    range col_range((col*2)+1, 0);
    
    return get_span_range_rect(row_range, col_range);
}

rect grid::get_row_divider_rect(const size_t& row) const {
    return get_span_range_rect(range(row*2), range(0, cols.size()));
}
rect grid::get_col_divider_rect(const size_t& col) const {
    return get_span_range_rect(range(0, rows.size()), range(col*2));
}

// returns a rectangle containing spans in row_range, col_range

rect grid::get_span_range_rect(const range& row_range, const range& col_range) const {
    double minr = rows[row_range.start].start;
    double maxr = rows[row_range.get_end()].get_end();
    
    double minc = cols[col_range.start].start;
    double maxc = cols[col_range.get_end()].get_end();
    
    return rect(point(minc, minr), point(maxc, maxr));
}

// returns the associated row and column span ranges corresponding to rect

void grid::get_span_ranges(range& row_range, range& col_range, const rect& rect) const {
    double rmin = rect.pmin.y;
    double rmax = rect.pmax.y;
    double cmin = rect.pmin.x;
    double cmax = rect.pmax.x;
    
    size_t rmini, rmaxi, cmini, cmaxi;
    
    get_span_index(rmini, rows, rmin, true);
    get_span_index(rmaxi, rows, rmax, true);
    get_span_index(cmini, cols, cmin, true);
    get_span_index(cmaxi, cols, cmax, true);
    
    row_range.start  = rmini;
    row_range.length = rmaxi - rmini;
    
    col_range.start  = cmini;
    col_range.length = cmaxi - cmini;
}

// returns by reference the area (and associated object if fixed) at point p

bool grid::get_cell_area(area& cell_area, __strong id& cell_obj, const point& p) {
    size_t row_idx, col_idx;

    return (get_cell_coord(row_idx, col_idx, p)) ? get_cell_area(cell_area, cell_obj, row_idx, col_idx) : false;
}

bool grid::get_cell_area(area& cell_area, __strong id& cell_obj, const size_t& row_idx, const size_t& col_idx) {
    if (row_idx < rows.size() && col_idx < cols.size()) {
        
        // fixed areas...
        for (auto pair : fixed) {
            if (pair.first.contains(row_idx, col_idx)) {
                cell_area = pair.first;
                cell_obj  = pair.second;
                
                return true;
            }
        }
        
        // standard areas...
        cell_area = area(row_idx, col_idx);
        cell_obj  = nil;
        
        return true;
    }
    
    return false;
}

bool grid::get_cell_coord(size_t& row_index, size_t& col_index, const point& p) {
    size_t ridx, cidx;

    if (get_span_index(ridx, rows, p.y)
        and get_span_index(cidx, cols, p.x)
        and is_cell(ridx) and is_cell(cidx)) {
        
        row_index = (ridx-1)/2;
        col_index = (cidx-1)/2;
        
        return true;
    }
    
    return false;
}

void grid::visit_row_dividers(const rect& rect, std::function<void(size_t, const struct rect&)>visitor) const {
    range row_range, col_range;
    get_span_ranges(row_range, col_range, rect);
    
    for (size_t ridx = is_divider(row_range.start) ? row_range.start : row_range.start + 1,
         rmax = row_range.get_end();
         ridx < rmax;
         ridx+=2) {
        
        visitor(ridx/2, get_span_range_rect(range(ridx), col_range));
    }
}

void grid::visit_col_dividers(const rect& rect, std::function<void(size_t, const struct rect&)>visitor) const {
    range row_range, col_range;
    get_span_ranges(row_range, col_range, rect);

    for (size_t cidx = is_divider(col_range.start) ? col_range.start : col_range.start + 1,
         cmax = col_range.get_end();
         cidx < cmax;
         cidx+=2) {
        
        visitor(cidx/2, get_span_range_rect(row_range, range(cidx)));
    }
}

void grid::visit_cells(const rect& rect, std::function<void(const area&, const struct rect&, __strong id)>visitor) const {
    range row_range, col_range;
    get_span_ranges(row_range, col_range, rect);
    
    for (size_t ridx = is_cell(row_range.start) ? row_range.start : row_range.start + 1,
         rmax = row_range.get_end();
         ridx <= rmax;
         ridx+=2) {
        for (size_t cidx = is_cell(col_range.start) ? col_range.start : col_range.start + 1,
             cmax = col_range.get_end();
             cidx <= cmax;
             cidx+=2) {

            size_t r = (ridx-1)/2;
            size_t c = (cidx-1)/2;
            
            bool is_fixed = false;

            for (auto pair : fixed) {
                if (pair.first.contains(r, c)) {
                    is_fixed = true;
                    break;
                }
            }
            
            if (!is_fixed) {
                area cell_area(r, c);
                visitor(cell_area, get_area_rect(cell_area), nil);
            }
        }
    }
    
    for (auto pair : fixed) {
        range rr(pair.first.rows.start*2+1, (pair.first.rows.length-1)*2);
        range cr(pair.first.cols.start*2+1, (pair.first.cols.length-1)*2);
        
        if (rr.intersects(row_range)
            and cr.intersects(col_range)) {
            
            visitor(pair.first, get_area_rect(pair.first), pair.second);
        }
    }
}
