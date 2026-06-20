// Learn — lists the real courses (ALL_COURSES) → modules → lessons.
// M1: course list with completion at 0; lesson player lands M3.

import SwiftUI
import MusicEngine

struct LearnView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.space3) {
                ForEach(ALL_COURSES, id: \.id) { course in
                    NavigationLink {
                        CourseDetailView(course: course)
                    } label: {
                        courseRow(course)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle("Learn")
        .screenBackground()
    }

    private func courseRow(_ course: Course) -> some View {
        CardSurface {
            HStack(spacing: Theme.space3) {
                Text(course.icon).font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text(courseName(course.id))
                        .font(.headline)
                        .foregroundStyle(palette.text)
                    Text("\(lessonCount(course)) lessons · \(course.level.rawValue)")
                        .font(.caption)
                        .foregroundStyle(palette.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(palette.textDim)
            }
        }
    }

    private func courseName(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func lessonCount(_ course: Course) -> Int {
        course.modules.reduce(0) { $0 + $1.lessons.count }
    }
}

/// Course detail — modules + lessons. M1 read-only outline.
struct CourseDetailView: View {
    @Environment(\.palette) private var palette
    let course: Course

    var body: some View {
        List {
            ForEach(course.modules, id: \.id) { module in
                Section(moduleTitle(module.id)) {
                    ForEach(module.lessons, id: \.id) { lesson in
                        HStack {
                            Text(lessonTitle(lesson.id))
                                .foregroundStyle(palette.text)
                            Spacer()
                            Text("\(lesson.steps.count) steps")
                                .font(.caption)
                                .foregroundStyle(palette.textDim)
                        }
                    }
                }
            }
        }
        .navigationTitle(courseName(course.id))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func courseName(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func moduleTitle(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
    private func lessonTitle(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}
