//
//  ProcessKiller.swift
//  Ram-Buddy
//
//  Created by Sabri Çetin on 15.04.2025.
//
import Foundation

class ProcessKiller {
    static func terminate(process: ProcessInfoModel) {
        // String türündeki pid'yi Int'e dönüştür
        guard let pidString = process.pid, let pid = Int(pidString) else {
            print("PID bulunamadı veya geçersiz.")
            return
        }

        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-9", "\(pid)"]  // PID'yi int yerine string olarak kullanabiliyoruz çünkü `kill` komutuna string olarak verilebilir
        
        do {
            try task.run()
            print("PID \(pid) başarıyla sonlandırıldı.")
        } catch {
            print("Kapatma hatası: \(error)")
        }
    }
}
