//
//  ContentView.swift
//  Ram-Buddy
//
//  Created by Sabri Çetin on 15.04.2025.
//
import SwiftUI

struct ContentView: View {
    @State private var usedMemoryMB: Int?
    @State private var totalMemoryMB: Int?
    @State private var topProcesses: [ProcessInfoModel] = []
    @State private var showAlert = false
    @State private var freedMemory: Int = 0

    // Yüzdeyi dışarda hesaplıyoruz
    var memoryUsagePercentage: Double {
        guard let used = usedMemoryMB, let total = totalMemoryMB, total > 0 else {
            return 0
        }
        return Double(used) / Double(total)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("RAMBuddy")
                .font(.largeTitle)
                .bold()

            if let used = usedMemoryMB, let total = totalMemoryMB {
                Text("Kullanılan RAM: \(used) MB / Toplam RAM: \(total) MB")
                    .font(.title2)

                ProgressBar(value: memoryUsagePercentage)
                    .frame(height: 20)
                    .padding(.horizontal)

                Text(String(format: "%%%.1f dolu", memoryUsagePercentage * 100))
                    .foregroundColor(.gray)
            } else {
                Text("RAM bilgisi alınamadı")
            }

            Button("RAM Bilgisini Güncelle") {
                updateMemoryInfo()
            }
            .padding()

            if !topProcesses.isEmpty {
                Text("En çok RAM kullanan uygulamalar:")
                    .font(.headline)

                List(topProcesses) { process in
                    ProcessRowView(process: process, onTerminate: updateMemoryInfo)  // Closure parametresi
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
        .onAppear {
            updateMemoryInfo()
        }
    }

    private func updateMemoryInfo() {
        usedMemoryMB = SystemStatsService.getUsedMemoryMB()
        totalMemoryMB = SystemStatsService.getTotalMemoryMB()
        topProcesses = SystemStatsService.getRunningAppProcesses()
        print("Top Processes: \(topProcesses.map { $0.command + " - " + $0.memoryMB })")
    }
}


struct ProgressBar: View {
    var value: Double  // 0.0 - 1.0 arasında olmalı

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray, lineWidth: 1)
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.blue)
                    .frame(width: geometry.size.width * CGFloat(value))
            }
        }
    }
}

struct ProcessRowView: View {
    let process: ProcessInfoModel
    @State private var showTerminateConfirmation = false
    var onTerminate: () -> Void  // Closure parametresi ekledik

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

            Button(action: {
                showTerminateConfirmation = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .help("Uygulamayı kapat")
            }
            .alert(isPresented: $showTerminateConfirmation) {
                Alert(
                    title: Text("Emin misiniz?"),
                    message: Text("Bu işlemi sonlandırmak istiyor musunuz? Açık veriler kaybolabilir."),
                    primaryButton: .destructive(Text("Kapat")) {
                        ProcessKiller.terminate(process: process)
                        onTerminate()  // Closure çağrılıyor, ContentView'deki güncelleme fonksiyonu çalışacak
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .padding(.vertical, 4)
    }
}




/*

 Çalışan kod bu
 
struct ContentView: View {
    @State private var usedMemoryMB: Int?
    @State private var totalMemoryMB: Int?
    @State private var topProcesses: [ProcessInfoModel] = []
    @State private var showAlert = false
    @State private var freedMemory: Int = 0
    @State private var memoryUsagePercentage: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("RAMBuddy")
                .font(.largeTitle)
                .bold()

            if let used = usedMemoryMB, let total = totalMemoryMB {
                Text("Kullanılan RAM: \(used) MB / Toplam RAM: \(total) MB")
                    .font(.title2)
                
                // memoryUsagePercentage'yi burada güncellemiyoruz
                
                ProgressBar(value: memoryUsagePercentage)
                
                    .frame(height: 20)
                    .padding(.horizontal)
            } else {
                Text("RAM bilgisi alınamadı")
            }

            Button("RAM Bilgisini Güncelle") {
                updateMemoryInfo()
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
                        updateMemoryInfo(freed: freed)
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
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

    private func updateMemoryInfo(freed: Int = 0) {
        usedMemoryMB = SystemStatsService.getUsedMemoryMB()
        totalMemoryMB = SystemStatsService.getUsedMemoryMB()
        topProcesses = SystemStatsService.getRunningAppProcesses()
        memoryUsagePercentage = calculateMemoryUsagePercentage()
        freedMemory = freed
        showAlert = freed > 0 // Eğer RAM temizlendiyse, alert'i göster
    }

    private func calculateMemoryUsagePercentage() -> Double {
        guard let used = usedMemoryMB, let total = totalMemoryMB, total > 0 else {
            return 0
        }
        return Double(used) / Double(total) * 100
    }
}

struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray, lineWidth: 1)
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.blue)
                    .frame(width: CGFloat(value) / 100 * geometry.size.width)
            }
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

*/

/*
 
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

 */
 
//
//#Preview {
//    ContentView()
//}
