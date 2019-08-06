//
//  Trip.swift
//  HackBikeApp
//
//  Created by Yasushi Sakai on 2/24/19.
//  Copyright © 2019 Yasushi Sakai. All rights reserved.
//

import Foundation

typealias Breadcrumb = Location

extension Breadcrumb {
    var csv: String {
        return "\(timestamp.epoch()),\(latitude),\(longitude)"
    }
}

class Trip{
    var started: Date
    var uuid: String
    private var breadCrumbs: [Breadcrumb]
    
    init(started: Date){
        self.started = started
        self.uuid = UUID.init().uuidString
        self.breadCrumbs = []
    }
}

extension Trip {
    func append(breadCrumb: Breadcrumb) {
        breadCrumbs.append(breadCrumb)
    }
    
    func breadCrumbString() -> [String] {
        return breadCrumbs.map { $0.csv }
    }
}
