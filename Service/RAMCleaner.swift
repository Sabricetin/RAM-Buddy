//
//  RAMCleaner.swift
//  Ram-Buddy
//
//  Created by Sabri Çetin on 15.04.2025.
//

import Foundation

class RAMCleaner {
    static func cleanRAM(completion: @escaping (Int) -> Void) {
        let before = SystemStatsService.getUsedMemoryMB()

        let task = Process()
        task.launchPath = "/usr/bin/purge"

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Hata: \(error.localizedDescription)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let after = SystemStatsService.getUsedMemoryMB()
            let freed = max(0, (before ?? 0) - (after ?? 0))
            completion(freed)
        }
    }
}
