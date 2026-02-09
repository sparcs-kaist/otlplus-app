//
//  SettingsView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/16/23.
//

import SwiftUI

@available(iOS 17.0, *)
struct SettingsView: View {
    @Binding var selectedSemester: SemesterElement?
    @Binding var selectedTimetable: Int
    
    @ObservedObject var viewModel = WatchViewModel()
    @AppStorage("refreshToken") var refreshToken: String = ""
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("userID") var userID: String = ""
    
    @State private var availableSemesters: [SemesterElement] = [SemesterElement]()
    @State private var availableTimetables: Int = 1
    
    var body: some View {
        NavigationStack {
            Group   {
                Form {
                    Picker("학기 선택", selection: self.$selectedSemester) {
                        ForEach(self.availableSemesters, id: \.self) { semester in
                            Text("\(String(semester.year)) \(getSemesterString(semester.semester))")
                                .tag(semester as SemesterElement?)
                        }
                    }
                    .onChange(of: self.selectedSemester) {
                        let encoder = JSONEncoder()
                        let defaults = UserDefaults.standard
                        if let encoded = try? encoder.encode(self.selectedSemester) {
                            defaults.set(encoded, forKey: "selectedSemester")
                        }
                        fetchTimetables()
                    }
                    Picker("시간표 선택", selection: self.$selectedTimetable) {
                        Text("내 시간표")
                            .tag(0)
                        ForEach(0..<self.availableTimetables, id: \.self) { i in
                            Text("시간표 \(i+1)")
                                .tag(i+1)
                        }
                    }
                    .onChange(of: self.selectedTimetable) {
                        let defaults = UserDefaults.standard
                        defaults.set(self.selectedTimetable, forKey: "selectedTimetable")
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            fetchSemesters()
            fetchTimetables()
        }
    }
    
    func fetchSemesters() {
        print("fetchData in SettingsView")
        let defaults = UserDefaults.standard
        if let semesterData = defaults.object(forKey: "selectedSemester") as? Data {
            let decoder = JSONDecoder()
            if let semester = try? decoder.decode(SemesterElement.self, from: semesterData) {
                self.selectedSemester = semester
            }
        }
        
        if let semesterData = defaults.object(forKey: "availableSemesters") as? Data {
            let decoder = JSONDecoder()
            if let semester = try? decoder.decode([SemesterElement].self, from: semesterData) {
                self.availableSemesters = semester
            }
        }
        
        let API: OTLAPI = OTLAPI.shared
        API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
        
        API.getActualSemesters(userID: self.userID) { results in
            switch results {
            case .success(let data):
                self.availableSemesters = data
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(data) {
                    defaults.set(encoded, forKey: "availableSemesters")
                }
            case .failure(_):
                print("failed")
            }
        }
    }
    
    func fetchTimetables() {
        let defaults = UserDefaults.standard
        self.selectedTimetable = defaults.integer(forKey: "selectedTimetable")
        self.availableTimetables = defaults.integer(forKey: "availableTimetables")
        
        if (self.selectedSemester != nil) {
            let API: OTLAPI = OTLAPI.shared
            API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
            
            API.getTimetables(userID: self.userID, year: self.selectedSemester!.year, semester: self.selectedSemester!.semester) { results in
                switch results {
                case .success(let data):
                    self.availableTimetables = data.count
                    defaults.set(data.count, forKey: "availableTimetables")
                case .failure(_):
                    print("failed")
                }
            }
        }
    }
    
    func getSemesterString(_ semester: Int) -> String {
        switch semester {
        case 1:
            return "봄"
        case 2:
            return "여름"
        case 3:
            return "가을"
        case 4:
            return "겨울"
        default:
            return "알수없음"
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    SettingsView(selectedSemester: .constant(SemesterElement(year: 2023, semester: 3)), selectedTimetable: .constant(0))
}
