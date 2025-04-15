//
//  SystemStatsService.swift
//  Ram-Buddy
//
//  Created by Sabri Çetin on 15.04.2025.
//

import Foundation
import AppKit

struct SystemStatsService {
    static func runShellCommand(_ command: String, arguments: [String] = []) -> String? {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            print("Komut çalıştırılamadı: \(command), hata: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }

    
    // Toplam RAM miktarını al
    static func getTotalMemoryMB() -> Int? {
        guard let output = runShellCommand("/usr/sbin/sysctl", arguments: ["-n", "hw.memsize"]) else { return nil }

        if let totalMemoryBytes = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return totalMemoryBytes / 1024 / 1024
        }
        return nil
    }

    static func killProcess(pid: Int) {
         let _ = runShellCommand("/bin/kill", arguments: ["-9", "\(pid)"])
     }
    
    //RAM kullanımı Miktarını al
    
    static func getUsedMemoryMB() -> Int? {
        guard let output = runShellCommand("/usr/bin/vm_stat") else { return nil }

        var pageSize: Int = 4096 // varsayılan page size
        var totalUsedPages = 0

        let lines = output.split(separator: "\n")
        for line in lines {
            if line.contains("page size of") {
                let comps = line.components(separatedBy: " ")
                if let pageStr = comps.last, let size = Int(pageStr) {
                    pageSize = size
                }
            } else if line.contains("Pages active") ||
                        line.contains("Pages wired down") ||
                        line.contains("Pages speculative") ||
                        line.contains("Pages occupied by compressor") {

                let parts = line.components(separatedBy: ":")
                if parts.count == 2, let valueStr = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: ".").first,
                   let pages = Int(valueStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) {
                    totalUsedPages += pages
                }
            }
        }

        let totalUsedBytes = totalUsedPages * pageSize
        return totalUsedBytes / 1024 / 1024
    }
}

struct ProcessInfoModel: Identifiable {
    let id = UUID()
    let pid: String?
    let command: String
    let memoryMB: String
    let icon: NSImage?
}

extension SystemStatsService {
  
    // Çalışan uygulamaların bilgilerini al
    static func getRunningAppProcesses(limit: Int = 5) -> [ProcessInfoModel] {
        
        let runningApps = NSWorkspace.shared.runningApplications
        var results: [ProcessInfoModel] = []

        guard let output = runShellCommand("/bin/ps", arguments: ["-axo", "pid,rss", "-ww"]) else { return [] }
        let lines = output.split(separator: "\n").dropFirst()

        var memoryMap: [Int: Int] = [:] // pid: rssKB

        for line in lines {
            let comps = line.trimmingCharacters(in: .whitespaces).split(separator: " ", omittingEmptySubsequences: true)
            guard comps.count >= 2,
                  let pid = Int(comps[0]),
                  let rss = Int(comps[1]) else { continue }
            memoryMap[pid] = rss
        }

        for app in runningApps {
            let pid = Int(app.processIdentifier)
            guard let name = app.localizedName,
                  let rssKB = memoryMap[pid] else { continue }

            let memMB = "\(rssKB / 1024) MB"
            let icon = app.icon // 👈 ikon burada alınıyor

            results.append(ProcessInfoModel(pid: String(pid), command: name, memoryMB: memMB, icon: icon))
        }

        return results
            .sorted {
                ($0.memoryMB.replacingOccurrences(of: " MB", with: "") as NSString).integerValue >
                ($1.memoryMB.replacingOccurrences(of: " MB", with: "") as NSString).integerValue
            }
            .prefix(limit)
            .map { $0 }
    }
    
    /*
    
    static func getRunningAppProcesses(limit: Int = 5) -> [ProcessInfoModel] {
        
        let runningApps = NSWorkspace.shared.runningApplications
        var results: [ProcessInfoModel] = []

        guard let output = runShellCommand("/bin/ps", arguments: ["-axo", "pid,rss", "-ww"]) else { return [] }
        let lines = output.split(separator: "\n").dropFirst()

        var memoryMap: [Int: Int] = [:] // pid: rssKB

        for line in lines {
            let comps = line.trimmingCharacters(in: .whitespaces).split(separator: " ", omittingEmptySubsequences: true)
            guard comps.count >= 2,
                  let pid = Int(comps[0]),
                  let rss = Int(comps[1]) else { continue }
            memoryMap[pid] = rss
        }

        for app in runningApps {
            let pid = Int(app.processIdentifier)
            guard let name = app.localizedName,
                  let rssKB = memoryMap[pid] else { continue }

            let memMB = "\(rssKB / 1024) MB"
            results.append(ProcessInfoModel(pid: String(pid), command: name, memoryMB: memMB))
        }

        return results
            .sorted {
                ($0.memoryMB.replacingOccurrences(of: " MB", with: "") as NSString).integerValue >
                ($1.memoryMB.replacingOccurrences(of: " MB", with: "") as NSString).integerValue
            }
            .prefix(limit)
            .map { $0 }
    }
*/
    
}
