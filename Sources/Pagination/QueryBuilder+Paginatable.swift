//
//  QueryBuilder+Paginatable.swift
//  Pagination
//
//  Created by Anthony Castelli on 4/5/18.
//

import Foundation
import Fluent
import Vapor

extension QueryBuilder where Model: Paginatable {
    public func paginate(page: Int, count: Int = Model.defaultPageSize, _ sorts: [QuerySort] = Model.defaultPageSorts) throws -> Future<Page<Model>> {
        // Make sure the current pzge is greater than 0
        guard page > 0 else {
            throw PaginationError.invalidPageNumber(page)
        }
        
        // Require page 1 or greater
        let page = page > 0 ? page : 1
        
        // Limit the query to the desired page
        let lowerBound = (page - 1) * count
        self.query.range = QueryRange(lower: lowerBound, upper: lowerBound + count)
        
        // Create the query
        // Add the sorts w/o replacing
        self.query.sorts.append(contentsOf: sorts)
        
        // Fetch the data
        return self.all().map(to: Page<Model>.self) { results in
            return try Page<Model>(
                number: page,
                data: results as! [Model],
                size: count,
                total: results.count
            )
        }
    }
}

extension QueryBuilder where Model: Paginatable, Model: Content {
    /// Returns a page-based response using page number from the request data
    public func paginate(for req: Request, key: String = Pagination.defaultPageKey, perKey: String = Pagination.defaultPagePerKey, _ sorts: [QuerySort] = Model.defaultPageSorts) throws -> Future<Page<Model>> {
        let page = try req.query.get(Int?.self, at: key) ?? 1
        var per = try req.query.get(Int?.self, at: perKey) ?? Model.defaultPageSize
        if let maxPer = Model.maxPageSize, per > maxPer {
            per = maxPer
        }
        return try self.paginate(
            page: page,
            count: per,
            sorts
        )
    }
    
    /// Returns a paginated response using page number from the request data
    public func paginate(for req: Request) throws -> Future<Paginated<Model>> {
        return try self.paginate(for: req).map(to: Paginated<Model>.self) { $0.response() }
    }
}
