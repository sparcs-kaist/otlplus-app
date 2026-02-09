//
//  WeeklyTableView.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/9/23.
//

import SwiftUI
import Alamofire

@available(iOS 17.0, *)
struct WeeklyTableView: View {
    @Binding var loginState: Bool
    
    @ObservedObject var viewModel = WatchViewModel()
    
    @AppStorage("refreshToken") var refreshToken: String = ""
    @AppStorage("accessToken") var accessToken: String = ""
    @AppStorage("userID") var userID: String = ""
    
    @State private var scrollOffset: CGFloat = CGFloat.zero
    @State private var showsSettingsView = false
    @State private var selectedSemester: SemesterElement? = nil
    @State private var selectedTimetable: Int = 0
    @State private var timetable: Timetable = Timetable(id: 0, lectures: [])
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Contents
                VStack {
                    Spacer()
                        .frame(height: 32)
                    ObservableScrollView(scrollOffset: self.$scrollOffset) {
                        ZStack {
                            TimelineLabelView()
                            HStack {
                                Spacer()
                                    .frame(width: 20)
                                NavigationLink(destination: DailyTableView(lectures: .constant(self.getLectureElements(atDay: .mon)), day: .constant(.mon))) {
                                    WeeklyDayView(lectures: .constant(self.getLectureElements(atDay: .mon)))
                                }.buttonStyle(.plain)
                                Spacer()
                                NavigationLink(destination: DailyTableView(lectures: .constant(self.getLectureElements(atDay: .tue)), day: .constant(.tue))) {
                                    WeeklyDayView(lectures: .constant(self.getLectureElements(atDay: .tue)))
                                }.buttonStyle(.plain)
                                Spacer()
                                NavigationLink(destination: DailyTableView(lectures: .constant(self.getLectureElements(atDay: .wed)), day: .constant(.wed))) {
                                    WeeklyDayView(lectures: .constant(self.getLectureElements(atDay: .wed)))
                                }.buttonStyle(.plain)
                                Spacer()
                                NavigationLink(destination: DailyTableView(lectures: .constant(self.getLectureElements(atDay: .thu)), day: .constant(.thu))) {
                                    WeeklyDayView(lectures: .constant(self.getLectureElements(atDay: .thu)))
                                }.buttonStyle(.plain)
                                Spacer()
                                NavigationLink(destination: DailyTableView(lectures: .constant(self.getLectureElements(atDay: .fri)), day: .constant(.fri))) {
                                    WeeklyDayView(lectures: .constant(self.getLectureElements(atDay: .fri)))
                                }.buttonStyle(.plain)
                                Spacer()
                            }
                        }.frame(height: 210)
                        
                        Button(action: {
                            self.showsSettingsView.toggle()
                        }, label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("시간표 설정")
                                    .fontWeight(.medium)
                            }
                        })
                        .padding(.top, 18)
                        .padding(.horizontal, 25)
                    }
                }
                
                
                // MARK: - Header
                VStack {
                    ZStack(alignment: .bottom) {
                        Color.black
                        HStack {
                            Spacer()
                                .frame(width: 22)
                            DayLabelView(day: .constant(.mon))
                            Spacer()
                            DayLabelView(day: .constant(.tue))
                            Spacer()
                            DayLabelView(day: .constant(.wed))
                            Spacer()
                            DayLabelView(day: .constant(.thu))
                            Spacer()
                            DayLabelView(day: .constant(.fri))
                            Spacer()
                        }.offset(y: -2)
                    }
                    .frame(height: 32)
                    .offset(y: self.scrollOffset < 0 ? -self.scrollOffset : 0)
                    Spacer()
                }
                
                
            }
            .navigationTitle("\((self.selectedSemester?.year ?? 2023) - 2000) \(getSemesterString(self.selectedSemester?.semester ?? 1))")
            .navigationDestination(isPresented: self.$showsSettingsView) {
                SettingsView(selectedSemester: self.$selectedSemester, selectedTimetable: self.$selectedTimetable)
            }
            .onChange(of: self.selectedSemester) {
                fetchTimetable()
            }
            .onChange(of: self.selectedTimetable) {
                fetchTimetable()
            }
        }
        .onAppear {
            fetchData()
            fetchTimetable()
        }
    }
    
    func fetchData() {
        let defaults = UserDefaults.standard
        if let semesterData = defaults.object(forKey: "selectedSemester") as? Data {
            let decoder = JSONDecoder()
            if let semester = try? decoder.decode(SemesterElement.self, from: semesterData) {
                self.selectedSemester = semester
            }
        }
        self.selectedTimetable = defaults.integer(forKey: "selectedTimetable")
        
        if (self.selectedSemester == nil) {
            let API: OTLAPI = OTLAPI.shared
            API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
            
            API.getActualSemesters(userID: self.userID) { results in
                switch results {
                case .success(let data):
                    self.selectedSemester = data.first
                case .failure(_):
                    self.loginState = false
                }
            }
        }
    }
    
    func fetchTimetable() {
        let defaults = UserDefaults.standard
        if let timetableData = defaults.object(forKey: "timetable") as? Data {
            let decoder = JSONDecoder()
            if let timetable = try? decoder.decode(Timetable.self, from: timetableData) {
                self.timetable = timetable
            }
        }
        if (self.selectedSemester != nil) {
            let API: OTLAPI = OTLAPI.shared
            API.setTokens(accessToken: accessToken, refreshToken: refreshToken)
            
            API.getActualTimetable(userID: self.userID, year: self.selectedSemester!.year, semester: self.selectedSemester!.semester) { results in
                switch results {
                case .success(let data):
                    var table = [Timetable]()
                    table.append(data.first!)
                    API.getTimetables(userID: self.userID, year: self.selectedSemester!.year, semester: self.selectedSemester!.semester) { results in
                        switch results {
                        case .success(let timetableData):
                            for timetable in timetableData {
                                table.append(timetable)
                            }
                            var index = self.selectedTimetable
                            if table.count-1 < self.selectedTimetable {
                                index = 0
                            }
                            self.timetable = table[index]
                            let encoder = JSONEncoder()
                            if let encoded = try? encoder.encode(table[index]) {
                                defaults.set(encoded, forKey: "timetable")
                            }
                        case .failure(let error):
                            if let err = error as? AFError, err.isResponseSerializationError {
                                self.loginState = false
                            }
                        }
                    }
                case .failure(let error):
                    if let err = error as? AFError, err.isResponseSerializationError {
                        self.loginState = false
                    }
                }
            }
        }
    }
    
    func getLectureElements(atDay: Days) -> [LectureElement] {
        var table = [LectureElement]()
        for lecture in self.timetable.lectures {
            for classtime in lecture.classtimes {
                if atDay.rawValue == classtime.day {
                    table.append(LectureElement(id: lecture.id, title: lecture.title, title_en: lecture.title_en, course: lecture.course, old_code: lecture.old_code, class_no: lecture.class_no, year: lecture.year, semester: lecture.semester, code: lecture.code, department: lecture.department, department_code: lecture.department_code, department_name: lecture.department_name, department_name_en: lecture.department_name_en, type: lecture.type, type_en: lecture.type_en, limit: lecture.limit, num_people: lecture.num_people, is_english: lecture.is_english, credit: lecture.credit, credit_au: lecture.credit_au, common_title: lecture.common_title, common_title_en: lecture.common_title_en, class_title: lecture.class_title, class_title_en: lecture.class_title_en, review_total_weight: lecture.review_total_weight, grade: lecture.grade, speech: lecture.speech, professors: lecture.professors, classtime: classtime, examtimes: lecture.examtimes))
                }
            }
        }
        
        return table
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
    WeeklyTableView(loginState: .constant(true))
}
