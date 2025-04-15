//
//  ContentView.swift
//  Ram-Buddy
//
//  Created by Sabri Çetin on 15.04.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var usedMemoryMB: Int?
    @State private var topProcesses: [ProcessInfoModel] = []
    @State private var showAlert = false
    @State private var freedMemory: Int = 0


    var body: some View {
        VStack(spacing: 20) {
            Text("RAMBuddy")
                .font(.largeTitle)
                .bold()

            if let used = usedMemoryMB {
                Text("Kullanılan RAM: \(used) MB")
                    .font(.title2)
            } else {
                Text("RAM bilgisi alınamadı")
            }

            Button("RAM Bilgisini Güncelle") {
                usedMemoryMB = SystemStatsService.getUsedMemoryMB()
                topProcesses = SystemStatsService.getRunningAppProcesses()
                print("Top Processes: \(topProcesses.map { $0.command + " - " + $0.memoryMB })")
            }
            .padding()

            if !topProcesses.isEmpty {
                Text("En çok RAM kullanan uygulamalar:")
                    .font(.headline)

                List(topProcesses) { process in
                    ProcessRowView(process: process)
                }
                Button("RAM Temizle") {
                    RAMCleaner.cleanRAM { freed in
                        usedMemoryMB = SystemStatsService.getUsedMemoryMB()
                        topProcesses = SystemStatsService.getRunningAppProcesses()
                        freedMemory = freed
                        showAlert = true
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                
                .frame(height: 300)

                .frame(height: 200)
            } else {
                Text("Veri bulunamadı.")
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 500, height: 600)
        .padding()
        
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("RAM Temizlendi"),
                message: Text("\(freedMemory) MB RAM boşaltıldı."),
                dismissButton: .default(Text("Tamam"))
            )
        }

    }
    
    
}
struct ProcessRowView: View {
    let process: ProcessInfoModel

    var body: some View {
        HStack(spacing: 12) {
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundColor(.gray)
                    )
            }

            Text(process.command)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(process.memoryMB)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

//
//#Preview {
//    ContentView()
//}
