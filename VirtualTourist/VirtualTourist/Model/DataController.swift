//
//  DataController.swift
//  VirtualTourist
//
//  Created by Lee, Steve on 12/3/18.
//  Copyright © 2018 Lee, Steve. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    static func shared() -> DataController {
        struct Singleton {
            static var shared = DataController(modelName: "VirtualTourist")
        }
        return Singleton.shared
    }
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autosaveViewContext(interval: 30)
            self.configureContexts()
            completion?()
        }
    }
    
    /////////
    
    func fetchPin(_ predicate: NSPredicate, dc: DataController, sorting: NSSortDescriptor? = nil) throws -> Pin? {
        let fr: NSFetchRequest<Pin> = Pin.fetchRequest()
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let pin = (try dc.viewContext.fetch(fr) as! [Pin]).first else {
            print("fetchPin return nil")
            return nil
        }
        print("fetchPin return pin")
        return pin

    }
    
    func fetchPhotos(_ predicate: NSPredicate, dc: DataController, sorting: NSSortDescriptor? = nil) throws -> [Photo]? {
        let fr: NSFetchRequest<Photo> = Photo.fetchRequest()
        fr.predicate = predicate
        if let sorting = sorting {
            fr.sortDescriptors = [sorting]
        }
        guard let photos = try dc.viewContext.fetch(fr) as? [Photo] else {
            print("fetchPin return nil")
            return nil
        }
        print("fetchPin return pin")
        return photos
    }
    
    func deletePhotos(predicate: NSPredicate, dc: DataController) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fr)
        do {
            try dc.viewContext.execute(deleteRequest)
        } catch {
            print("deletePhotos error")
        }

    }
}

extension DataController {
    func autosaveViewContext(interval: TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveViewContext(interval: interval)
        }
    }  
}
