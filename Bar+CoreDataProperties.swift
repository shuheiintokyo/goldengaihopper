//
//  Bar+CoreDataProperties.swift
//  GoldenPeace
//
//  Created by Shuhei Kinugasa on 2025/03/15.
//
//

import Foundation
import CoreData


extension Bar {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bar> {
        return NSFetchRequest<Bar>(entityName: "Bar")
    }

    @NSManaged public var isVisited: Bool
    @NSManaged public var locationColumn: Int16
    @NSManaged public var locationRow: Int16
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var uuid: String?
    @NSManaged public var cellSpanHorizontal: Int16
    @NSManaged public var cellSpanVertical: Int16

}

extension Bar : Identifiable {

}
