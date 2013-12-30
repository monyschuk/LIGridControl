//
//  grid.cpp
//  LIGrid
//
//  Created by Mark Onyschuk on 12/3/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#include "grid.h"

using namespace li::grid;
using namespace li::geom;

bool grid::empty() const {
    return rows.empty() || cols.empty();
}

#pragma mark -
#pragma mark Construction

void grid::clear() {
    rows.clear();
    cols.clear();
    fixed.clear();
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


void grid::reserve_rows(int_t nrows) {
    rows.reserve(nrows*2 + 1);
}
void grid::reserve_cols(int_t ncols) {
    cols.reserve(ncols*2 + 1);
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

#pragma mark -
#pragma mark Grid Layout

// returns true if value exists within the given span list, and populates index with the index of
// the span that contains value. if match_nearest is true then the nearest matching index is returned.

static bool get_span_index(int_t& index, const span_list& spans, const double value, bool match_nearest = false) {
    int_t len = spans.size();
    
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
        
        int_t imin = 0, imax = len - 1;
        
        while (imax >= imin) {
            int_t  imid = (imin + imax) / 2;
            
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

bool grid::get_fixed_areas(std::vector<area>& fixed_areas, std::vector<__strong id>& fixed_objs, const interval& row_interval, const interval& col_interval) {
    bool found = false;
    
    for (auto pair : fixed) {
        if (pair.first.rows.intersects(row_interval) && pair.first.cols.intersects(col_interval)) {
            fixed_areas.push_back(pair.first);
            fixed_objs.push_back(pair.second);
            
            found = true;
        }
    }
    
    return found;
}

rect grid::get_area_rect(const area& cell_area) const {
    int_t minr = cell_area.rows.first;
    int_t minc = cell_area.cols.first;
    
    int_t maxr = cell_area.rows.second;
    int_t maxc = cell_area.cols.second;

    rect   minrect = get_area_rect(minr, minc);
    rect   maxrect = get_area_rect(maxr, maxc);
    
    return minrect.union_rect(maxrect);
}

rect grid::get_area_rect(const int_t& row, const int_t& col) const {
    interval row_range = interval(row).to_span_interval();
    interval col_range = interval(col).to_span_interval();
    
    return get_span_interval_rect(row_range, col_range);
}

rect grid::get_row_divider_rect(const int_t& row) const {
    interval row_range = interval(row).to_span_interval();
    interval col_range = interval(0, get_col_count() - 1).to_span_interval();
    
    return get_span_interval_rect(row_range, col_range);
}
rect grid::get_col_divider_rect(const int_t& col) const {
    interval row_range = interval(0, get_row_count() - 1).to_span_interval();
    interval col_range = interval(col).to_span_interval();
    
    return get_span_interval_rect(row_range, col_range);
}

// returns a rectangle containing spans in row_range, col_range

rect grid::get_span_interval_rect(const interval& row_span_interval, const interval& col_span_interval) const {
    double minr = rows[row_span_interval.first].start;
    double maxr = rows[row_span_interval.second].get_end();
    
    double minc = cols[col_span_interval.first].start;
    double maxc = cols[col_span_interval.second].get_end();
    
    return rect(point(minc, minr), point(maxc, maxr));
}

// returns the associated row and column span ranges corresponding to rect

void grid::get_span_intervals(interval& row_span_range, interval& col_span_range, const rect& rect) const {
    double rmin = rect.pmin.y;
    double rmax = rect.pmax.y;
    double cmin = rect.pmin.x;
    double cmax = rect.pmax.x;
    
    int_t rmin_idx = 0, rmax_idx = 0, cmin_idx = 0, cmax_idx = 0;
    
    get_span_index(rmin_idx, rows, rmin, true);
    get_span_index(rmax_idx, rows, rmax, true);
    get_span_index(cmin_idx, cols, cmin, true);
    get_span_index(cmax_idx, cols, cmax, true);
    
    row_span_range.first  = rmin_idx;
    row_span_range.second = rmax_idx;
    
    col_span_range.first  = cmin_idx;
    col_span_range.second = cmax_idx;
}

// returns by reference the area (and associated object if fixed) at point p

bool grid::get_cell_area(area& cell_area, __strong id& cell_obj, const point& p) {
    int_t row_idx, col_idx;

    return (get_cell_coord(row_idx, col_idx, p)) ? get_cell_area(cell_area, cell_obj, row_idx, col_idx) : false;
}

// returns by reference the area (and associated object if fixed) at (row_idx, col_idx)

bool grid::get_cell_area(area& cell_area, __strong id& cell_obj, const int_t& row_idx, const int_t& col_idx) {
    if (row_idx < rows.size() && col_idx < cols.size()) {
        
        // check fixed areas...
        for (auto pair : fixed) {
            if (pair.first.contains(row_idx, col_idx)) {
                cell_area = pair.first;
                cell_obj  = pair.second;
                
                return true;
            }
        }
        
        // it's a standard area...
        cell_area = area(row_idx, col_idx);
        cell_obj  = nil;
        
        return true;
    }
    
    return false;
}

// returns the cell row and column indexes at point p

bool grid::get_cell_coord(int_t& row_index, int_t& col_index, const point& p) {
    int_t row_span_index, col_span_index;

    if (get_span_index(row_span_index, rows, p.y)
        and get_span_index(col_span_index, cols, p.x)
        and is_cell(row_span_index) and is_cell(col_span_index)) {
        
        row_index = (row_span_index-1)/2;
        col_index = (col_span_index-1)/2;
        
        return true;
    }
    
    return false;
}

#pragma mark -
#pragma mark Grid Drawing

void grid::visit_row_dividers(const rect& rect, std::function<void(int_t, const struct rect&)>visitor) const {
    interval row_span_interval, col_span_interval;
    get_span_intervals(row_span_interval, col_span_interval, rect);
    
    for (int_t span_idx = is_divider(row_span_interval.first) ? row_span_interval.first : row_span_interval.first + 1,
         max_span_idx = row_span_interval.second;
         span_idx <= max_span_idx;
         span_idx+=2) {
        
        int_t div_idx = span_idx/2;
        
        visitor(div_idx, get_span_interval_rect(interval(span_idx), col_span_interval));
    }
}

void grid::visit_col_dividers(const rect& rect, std::function<void(int_t, const struct rect&)>visitor) const {
    interval row_span_interval, col_span_interval;
    get_span_intervals(row_span_interval, col_span_interval, rect);

    for (int_t span_idx = is_divider(col_span_interval.first) ? col_span_interval.first : col_span_interval.first + 1,
         max_span_idx = col_span_interval.second;
         span_idx <= max_span_idx;
         span_idx+=2) {
        
        int_t div_idx = span_idx/2;
        
        visitor(div_idx, get_span_interval_rect(row_span_interval, interval(span_idx)));
    }
}

void grid::visit_cells(const rect& rect, std::function<void(const area&, const struct rect&, __strong id)>visitor) const {
    interval row_span_interval, col_span_interval;
    get_span_intervals(row_span_interval, col_span_interval, rect);
    
    for (int_t row_span_idx = is_cell(row_span_interval.first) ? row_span_interval.first : row_span_interval.first + 1,
         max_row_span_idx = row_span_interval.second;
         row_span_idx <= max_row_span_idx;
         row_span_idx+=2) {
        
        for (int_t col_span_idx = is_cell(col_span_interval.first) ? col_span_interval.first : col_span_interval.first + 1,
             max_col_span_idx = col_span_interval.second;
             col_span_idx <= max_col_span_idx;
             col_span_idx+=2) {

            int_t r = (row_span_idx-1)/2;
            int_t c = (col_span_idx-1)/2;
            
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
        interval fixed_row_span_interval = pair.first.rows.to_span_interval();
        interval fixed_col_span_interval = pair.first.cols.to_span_interval();
        
        if (fixed_row_span_interval.intersects(row_span_interval)
            and fixed_col_span_interval.intersects(col_span_interval)) {
            
            visitor(pair.first, get_area_rect(pair.first), pair.second);
        }
    }
}
