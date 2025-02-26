import SwiftUI
import Charts

struct StatsView: View {
  let visitedLocations: [VisitedLocation]

  let worldArea: Double = 510_072_000
  let locationArea = 0.06 * 0.06 * Double.pi
  var visitedArea: Double { locationArea * Double(visitedLocations.count) / worldArea }
  var todayArea: Double {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let locations = visitedLocations.filter {
      calendar.startOfDay(for: $0.firstVisited ?? Date(timeIntervalSince1970: 1740133975)) == today
    }
    return locationArea * Double(locations.count) / worldArea
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // Stats cards
        StatCard(
          title: "All Time Exploration",
          value: String(format: "%.6f", visitedArea * 10000),
          unit: "‱",
          icon: "map.fill"
        )

        StatCard(
          title: "Today's Exploration",
          value: String(format: "%.6f", todayArea * 10000),
          unit: "‱",
          icon: "calendar"
        )

        // Fixed-height chart
        VisitsChartView(visitedLocations: visitedLocations)
      }
      .padding(.vertical)
      .padding(.horizontal)
    }
  }
}

// A helper struct to store (date, cumulativeCount)
struct DailyVisitData: Identifiable {
  let date: Date
  let cumulativeCount: Int

  var id: Date { date }
}

func makeCumulativeDailyData(from locations: [VisitedLocation]) -> [DailyVisitData] {
  guard !locations.isEmpty else { return [] }

  // 1) Group visitedLocations by day
  //    Key: startOfDay date
  var groupedByDay: [Date: Int] = [:]
  let calendar = Calendar.current

  for loc in locations {
    let day = calendar.startOfDay(for: loc.firstVisited ?? Date(timeIntervalSince1970: 1740133975))
    groupedByDay[day, default: 0] += 1
  }

  // 2) Sort keys (dates) ascending
  let sortedKeys = groupedByDay.keys.sorted()

  // 3) Create a cumulative sum
  var cumulativeData: [DailyVisitData] = []
  var runningTotal = 0

  for day in sortedKeys {
    guard let visitsThisDay = groupedByDay[day] else { continue }
    runningTotal += visitsThisDay

    let dailyData = DailyVisitData(date: day, cumulativeCount: runningTotal)
    cumulativeData.append(dailyData)
  }

  return cumulativeData
}

struct VisitsChartView: View {
  let visitedLocations: [VisitedLocation]

  // Define a fixed height for the chart
  private let chartHeight: CGFloat = 200

  // Calculate some statistics for annotations
  private var totalLocations: Int {
    visitedLocations.count
  }

  private var firstDate: Date? {
    visitedLocations.compactMap { $0.firstVisited }.min()
  }

  private var dateRange: String {
    guard let first = firstDate else { return "No data" }

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none

    let startDate = formatter.string(from: first)
    let endDate = formatter.string(from: Date())

    return "\(startDate) - \(endDate)"
  }

  var body: some View {
    // 1) Convert to cumulative daily data
    let dailyData = makeCumulativeDailyData(from: visitedLocations)

    VStack(alignment: .leading, spacing: 8) {
      // Chart title and metadata
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Exploration Progress")
            .font(.headline)

          Text(dateRange)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // The chart with fixed height
      Chart {
        ForEach(dailyData) { dataPoint in
          LineMark(
            x: .value("Day", dataPoint.date),
            y: .value("Locations", dataPoint.cumulativeCount)
          )
          .foregroundStyle(Color.blue.gradient)
          .lineStyle(StrokeStyle(lineWidth: 2.5))
          .interpolationMethod(.catmullRom)
          .symbol {
            Circle()
              .fill(Color.blue)
              .frame(width: 6, height: 6)
          }

          AreaMark(
            x: .value("Day", dataPoint.date),
            y: .value("Locations", dataPoint.cumulativeCount)
          )
          .foregroundStyle(
            LinearGradient(
              colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .interpolationMethod(.catmullRom)
        }

        // Add annotation for the latest point if we have data
        if let lastPoint = dailyData.last {
          PointMark(
            x: .value("Day", lastPoint.date),
            y: .value("Locations", lastPoint.cumulativeCount)
          )
          .foregroundStyle(Color.blue)
          .symbolSize(100)

          RuleMark(
            x: .value("Day", lastPoint.date),
            yStart: .value("Start", 0),
            yEnd: .value("End", lastPoint.cumulativeCount)
          )
          .foregroundStyle(.gray.opacity(0.3))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
      }
      .frame(height: chartHeight) // Fixed height
      .chartXAxis {
        AxisMarks(values: .stride(by: .day)) { value in
          AxisGridLine()
          AxisValueLabel(format: .dateTime.day().month(.abbreviated))
        }
      }
      .chartYAxis {
        AxisMarks {
          AxisGridLine()
//          AxisValueLabel()
        }
      }
      .chartYScale(domain: .automatic(includesZero: true))
      .chartLegend(.hidden)
    }
    .padding()
    .background(Color(UIColor.secondarySystemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
  }
}

// Helper view for stat cards
struct StatCard: View {
  let title: String
  let value: String
  let unit: String
  let icon: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(.blue)
        Text(title)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      HStack(alignment: .firstTextBaseline) {
        Text(value)
          .font(.title2)
          .fontWeight(.bold)

        Text(unit)
          .font(.headline)
          .foregroundColor(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color(UIColor.secondarySystemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
  }
}

// Helper view for stats rows
struct StatsRowView: View {
  let title: String
  let value: String
  let icon: String

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(.blue)
        .frame(width: 24, height: 24)

      Text(title)
        .foregroundColor(.secondary)

      Spacer()

      Text(value)
        .fontWeight(.medium)
    }
  }
}
