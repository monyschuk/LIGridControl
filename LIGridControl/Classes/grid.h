//
//  grid.h
//  LIGridControl
//
//  Created by Mark Onyschuk on 12/3/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#ifndef __LIGridControl__grid__
#define __LIGridControl__grid__

#include <map>
#include <vector>
#include <algorithm>

#include <iostream>

#import <Foundation/Foundation.h>

namespace li {
    namespace geom {
        
        struct point {
            double x, y;
            
            point() : x(0), y(0) {}
            point(double x, double y) : x(x), y(y) {}
            
            point operator+(const point& p) const {
                return point(x + p.x, y + p.y);
            }
            point operator-(const point& p) const {
                return point(x - p.x, y - p.y);
            }
            
            point minima(const point& p) const {
                return point(std::min(x, p.x), std::min(y, p.y));
            }
            point maxima(const point& p) const {
                return point(std::max(x, p.x), std::max(y, p.y));
            }
            
            // conversion
            point(const CGPoint& p) {
                x = p.x;
                y = p.y;
            }
            operator CGPoint() const {
                return CGPointMake(x, y);
            }
        };
        
        struct rect {
            point pmin, pmax;
            
            rect() {};
            rect(const point& pmin, const point& pmax) : pmin(pmin), pmax(pmax) {}
            rect(double x, double y, double w, double h) : pmin(point(x, y)), pmax(point(x + w, y + h)) {}
            
            rect union_rect(const rect& r) const {
                return rect(pmin.minima(r.pmin), pmax.maxima(r.pmax));
            }
            rect intersection_rect(const rect& r) const {
                return rect(pmin.maxima(r.pmin), pmax.minima(r.pmax));
            }
            
            bool intersects(const rect& r) {
                return !(pmax.x < r.pmin.x or pmax.y < r.pmin.y or r.pmax.x < pmin.x or r.pmax.y < pmin.y);
            }
            
            // conversion
            rect(const CGRect& r) {
                pmin.x = r.origin.x;
                pmin.y = r.origin.y;
                pmax.x = r.origin.x + r.size.width;
                pmax.y = r.origin.y + r.size.height;
            }
            operator CGRect() const {
                return CGRectMake(pmin.x, pmin.y, pmax.x - pmin.x, pmax.y - pmin.y);
            }
        };
    }

    namespace grid {
        using namespace li::geom;
        
        // an abstract interval, used to represent both
        // a geometric range along a row (y) or column (x) axis,
        // as well as a range of indices into a list of these
        // geometric ranges.
        
        template <class T>
        struct interval {
            T start, length;
            
            interval() : start(0), length(0) {}
            interval(T v) : start(v), length(0) {}
            interval(T start, T length) : start(start), length(length) {}
            
            bool operator<(const interval<T>& i) const {
                return (start < i.start) or (start == i.start and length < i.length);
            }
            
            bool contains(T v) const {
                return (v >= start && v < start + length);
            }
            
            bool intersects(const interval& i) const {
                T minA = start, maxA = start + length;
                T minB = i.start, maxB = i.start + i.length;
                
                return !(minA > maxB || maxA < minB);
            }

            T get_end() const {
                return start + length;
            }
        };
        
        // span is the basic unit of grid layout, it can be either a row or column span,
        // and depending upon its location in the list of rows or columns, its either a
        // divider or cell span...
        //
        // cells live on odd indexes - that's to say that in a list of spans, the first
        // is a divider (index=0, even), then a cell (index=1, odd), and so on until we reach
        // the last divider (index=N, even). in general, this means that for a grid of size N x M
        // we hold (N * 2 + 1) row spans and (M * 2 + 1) column spans
        
        typedef interval<float>     span;
        typedef interval<size_t>    range;

        typedef std::vector<span>   span_list;
        
        // area is a grid slice, expressed as a range of row and column *cells* within a grid.
        // note that this is a row of cells, and not dividers, so indexes into the underlying grid
        // are all at 2x+1 offset into their respective row and column span lists.
        
        class area {
        public:
            range rows, cols;
            
            area() : rows(0), cols(0) {}
            area(size_t row, size_t col) : rows(row), cols(col) {}
            area(const range& rows, const range& cols) : rows(rows), cols(cols) {}
                        
            bool contains(size_t row, size_t col) const {
                return rows.contains(row) && cols.contains(col);
            }
            
            // area ordering is row dominant - an area whose row range is less than another area's
            // row range is considered smaller than the other, otherwise we compare column ranges.
            // the end result is that areas within a map are ordered first by row and then by column.
            
            bool operator<(const area& a) const {
                if (rows < a.rows) return true;
                if (a.rows < rows) return false;
                
                if (cols < a.cols) return true;
    
                return false;
            }
        };
        
        typedef std::map<area, __strong id> area_map;
        
        // a grid is a series of row, column, and divider spans, as well as what are called fixed areas
        // that extend across multiple rows and columns and that have associated objective-c
        // objects that distinguish them from each other.
        
        class grid {
            area_map  fixed;
            span_list rows, cols;
            
        public:
            grid() {}

            void clear();
            bool empty() const;
            
            // call reserve..() prior to pushing rows and columns for better performance
            void reserve_rows(size_t nrows);
            void reserve_cols(size_t ncols);
            
            void push_row(float size);
            void push_col(float size);
            
            void push_row_divider(float size);
            void push_col_divider(float size);

            void push_fixed(const area& fixed, __strong id obj);

            size_t get_row_count() const { return rows.size(); }
            size_t get_col_count() const { return cols.size(); }
            
            float get_width() const { return cols.empty() ? 0 : cols.back().get_end(); }
            float get_height() const { return rows.empty() ? 0 : rows.back().get_end(); }
            
            bool get_cell_coord(size_t& row_idx, size_t& col_idx, const point& p);

            bool get_cell_area(area& cell_area, __strong id& cell_obj, const point& p);
            bool get_cell_area(area& cell_area, __strong id& cell_obj, const size_t& row_idx, const size_t& col_idx);
            
            bool get_fixed_areas(std::vector<area>& fixed_areas, std::vector<__strong id>& fixed_objs, const range& cell_row_range, const range& cell_column_range);
            
            rect get_area_rect(const area& cell_area) const;
            rect get_area_rect(const size_t& row, const size_t& col) const;
            
            rect get_row_divider_rect(const size_t& row) const;
            rect get_col_divider_rect(const size_t& col) const;
            
            rect get_span_range_rect(const range& row_range, const range& col_range) const;
            void get_span_ranges(range& row_range, range& col_range, const rect& rect) const;

            void visit_row_dividers(const rect& rect, std::function<void(size_t, const struct rect&)>visitor) const;
            void visit_col_dividers(const rect& rect, std::function<void(size_t, const struct rect&)>visitor) const;

            void visit_cells(const rect& rect, std::function<void(const area&, const struct rect&, __strong id)>visitor) const;
        };
    }
}
#endif /* defined(__LIGridControl__grid__) */
