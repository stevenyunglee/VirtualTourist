//
//  GCD.swift
//  VirtualTourist
//
//  Created by Lee, Steve on 12/3/18.
//  Copyright © 2018 Lee, Steve. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
