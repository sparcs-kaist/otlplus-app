// Run against the Foundation models in ios/OTLWidgets/OTLAPI.swift.
import Foundation

let customJSON = #"{"lectures":[],"timetableItems":[{"kind":"custom","data":{"id":12,"block_name":"Study","place":"Library","times":[{"day":0,"begin":60,"end":120},{"day":6,"begin":1380,"end":1440}]}}]}"#
let table = try JSONDecoder().decode(Timetable.self, from: Data(customJSON.utf8))
assert(table.scheduleItems.count == 1)
assert(table.scheduleItems[0].classes.count == 2)
assert(table.scheduleItems[0].courseId == 11)
assert(table.scheduleItems[0].professors.isEmpty)
assert(table.scheduleItems[0].classes.last!.place == "Library")
let sunday = ISO8601DateFormatter().date(from: "2026-09-27T14:30:00Z")!
let next = nextWidgetItem(timetable: table, date: sunday)!
assert(next.1.classes[next.0].day == 0)
assert(next.1.classes[next.0].begin == 60)
let atStart = ISO8601DateFormatter().date(from: "2026-09-27T14:00:00Z")!
assert(nextWidgetItem(timetable: table, date: atStart)!.1.classes[1].day == 6)
assert(nextWidgetItem(timetable: Timetable(lectures: []), date: sunday) == nil)
let cached = try JSONDecoder().decode(Timetable.self, from: JSONEncoder().encode(table))
assert(cached.customBlocks == table.customBlocks)
let myTable = try JSONDecoder().decode(Timetable.self, from: Data(#"{"lectures":[]}"#.utf8))
assert(myTable.customBlocks.isEmpty)
let invalid = WidgetCustomBlock(id: 1, blockName: "Invalid", place: "", times: [WidgetCustomTime(day: 0, begin: 60, end: 30)])
assert(Timetable(lectures: [], customBlocks: [invalid]).scheduleItems.isEmpty)
print("iOS widget schedule checks passed")

let cacheJSON = #"{"lectures":[],"custom_blocks":[{"id":1,"block_name":"Cached","place":"","day":0,"begin":600,"end":660}]}"#
let appCache = try JSONDecoder().decode(Timetable.self, from: Data(cacheJSON.utf8))
assert(appCache.customBlocks[0].blockName == "Cached")
assert(appCache.scheduleItems[0].classes[0].begin == 600)
assert(!myTable.hasCustomItems)
let malformedJSON = #"{"lectures":[],"timetableItems":[{"kind":"custom","data":{"id":1}},{"kind":"custom","data":{"id":2,"block_name":"Valid","times":[{"day":0,"begin":600,"end":660}]}}]}"#
let partial = try JSONDecoder().decode(Timetable.self, from: Data(malformedJSON.utf8))
assert(partial.customBlocks.count == 1)

let morningDate = ISO8601DateFormatter().date(from: "2026-09-27T15:00:00Z")!
let morningWindow = widgetTimeWindow(timetable: table, date: morningDate)
assert(morningWindow.startHour == 1 && morningWindow.endHour == 9)
let daytimeDate = ISO8601DateFormatter().date(from: "2026-09-28T01:00:00Z")!
let daytimeWindow = widgetTimeWindow(timetable: table, date: daytimeDate)
assert(daytimeWindow.startHour == 9 && daytimeWindow.endHour == 17)
let eveningDate = ISO8601DateFormatter().date(from: "2026-09-28T14:00:00Z")!
let eveningWindow = widgetTimeWindow(timetable: table, date: eveningDate)
assert(eveningWindow.startHour == 16 && eveningWindow.endHour == 24)
let ongoing = ISO8601DateFormatter().date(from: "2026-09-27T16:30:00Z")!
assert(remainingWidgetItems(timetable: table, date: ongoing).count == 1)
let after = ISO8601DateFormatter().date(from: "2026-09-27T17:00:00Z")!
assert(remainingWidgetItems(timetable: table, date: after).isEmpty)
