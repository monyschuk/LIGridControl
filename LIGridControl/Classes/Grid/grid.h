//
//  grid.h
//  LIGrid
//
//  Created by Mark Onyschuk on 12/3/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#ifndef __LIGrid__grid__
#define __LIGrid__grid__

#include <map>
#include <cmath>
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
        
        // span is the basic unit of grid layout, it can be either a row or column span,
        // and depending upon its location in the list of rows or columns, its either a
        // divider or cell span...
        //
        // cells live on odd indexes - that's to say that in a list of spans, the first
        // is a divider (index=0, even), then a cell (index=1, odd), and so on until we reach
        // the last divider (index=N, even). in general, this means that for a grid of size N x M
        // we hold (N * 2 + 1) row spans and (M * 2 + 1) column spans
        
        struct span {
            float start, length;
            
            span() : start(0), length(0) {}
            span(float v) : start(v), length(0) {}
            span(float s, float l) : start(s), length(l) {}
            
            inline float get_end() const {
                return start + length;
            }
        };
        
        typedef std::vector<span> span_list;

        // interval represents ranges of cells along the row or column axis,
        // or ranges of spans along the row or column axis, convertable through
        // member functions.
        
        typedef NSUInteger int_t;
        typedef NSInteger  sint_t;
        
        struct interval;
        struct span_interval;
        
        struct interval {
            int_t first, second;
            
            interval() : first(0), second(0) {}
            interval(int_t v) : first(v), second(v) {}
            interval(int_t f, int_t s) : first(std::min(f, s)), second(std::max(f, s)) {}
            
            inline int_t length() const {
                return (second - first) + 1;
            }
            
            bool contains(const int_t& v) const {
                return (v >= first && v <= second);
            }
            bool intersects(const interval& i) const {
                return (contains(i.first) or contains(i.second) or i.contains(first) or i.contains(second));
            }

            bool operator<(const interval& i) const {
                return (first < i.first) or ((first == i.first) && second < i.second);
            }
            
            // conversion
            operator NSRange() const {
                return NSMakeRange(first, second - first + 1);
            }
            interval(const NSRange& r) : first(r.location), second((r.length > 0) ? r.location + r.length - 1 : r.location) {}

            // span/cell interval conversion
            inline interval to_span_interval() const {
                return interval(first*2+1, second*2+1);
            }
            inline interval to_cell_interval() const {
                return interval((first-1)/2, (second-1)/2);
            }
        };
        
        // area is a range of row and column cells within a grid.
        
        struct area {
            interval rows, cols;
            
            area() : rows(0), cols(0) {}
            area(int_t row, int_t col) : rows(row), cols(col) {}
            area(const interval& rows, const interval& cols) : rows(rows), cols(cols) {}
                        
            bool contains(int_t row, int_t col) const {
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
        // that may extend across multiple rows and columns and that have associated objective-c
        // objects to distinguish them from each other.
        
        class grid {
            area_map fixed;
            span_list rows, cols;
            
        public:
            grid() {}

            bool empty() const;

            // construction
            void clear();
            
            void reserve_rows(int_t nrows);
            void reserve_cols(int_t ncols);
            
            void push_row(float size);
            void push_col(float size);
            
            void push_row_divider(float size);
            void push_col_divider(float size);

            void push_fixed(const area& fixed, __strong id obj);

            // grid layout
            int_t get_row_count() const { return rows.size(); }
            int_t get_col_count() const { return cols.size(); }
            
            float get_width() const { return cols.empty() ? 0 : cols.back().get_end(); }
            float get_height() const { return rows.empty() ? 0 : rows.back().get_end(); }
            
            bool get_cell_coord(int_t& row_idx, int_t& col_idx, const point& p);

            bool get_cell_area(area& cell_area, __strong id& cell_obj, const point& p);
            bool get_cell_area(area& cell_area, __strong id& cell_obj, const int_t& row_idx, const int_t& col_idx);
            
            bool get_fixed_areas(std::vector<area>& fixed_areas, std::vector<__strong id>& fixed_objs, const interval& row_interval, const interval& column_interval);
            
            rect get_area_rect(const area& cell_area) const;
            rect get_area_rect(const int_t& row, const int_t& col) const;
            
            rect get_row_divider_rect(const int_t& row) const;
            rect get_col_divider_rect(const int_t& col) const;
            
            rect get_span_interval_rect(const interval& row_span_interval, const interval& col_span_interval) const;
            void get_span_intervals(interval& row_span_interval, interval& col_span_interval, const rect& rect) const;

            // grid drawing
            void visit_row_dividers(const rect& rect, std::function<void(int_t, const struct rect&)>visitor) const;
            void visit_col_dividers(const rect& rect, std::function<void(int_t, const struct rect&)>visitor) const;

            void visit_cells(const rect& rect, std::function<void(const area&, const struct rect&, __strong id)>visitor) const;
        };
    }
}
#endif /* defined(__LIGrid__grid__) */
