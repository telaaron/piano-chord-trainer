// Learn — lists the real courses (ALL_COURSES) → modules → lessons.
// M1: course list with completion at 0; lesson player lands M3.

import SwiftUI
import MusicEngine

extension Lesson: @retroactive Identifiable {}

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
            .readableWidth()
        }
        .navigationTitle("Learn")
        .screenBackground()
    }

    private func courseRow(_ course: Course) -> some View {
        let pct = CourseProgressStore.shared.completionPercent(for: course)
        return CardSurface {
            HStack(spacing: Theme.space3) {
                ZStack {
                    Circle().fill(palette.primary.opacity(0.14)).frame(width: 46, height: 46)
                    Image(systemName: AppIcons.course(course.id))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(palette.primary)
                        .symbolRenderingMode(.hierarchical)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(courseName(course.id))
                        .font(Display.headline(18))
                        .foregroundStyle(palette.text)
                    Text("\(lessonCount(course)) lessons · \(course.level.rawValue)")
                        .font(.caption)
                        .foregroundStyle(palette.textMuted)
                    if pct > 0 {
                        ProgressView(value: Double(pct), total: 100)
                            .tint(palette.primary)
                            .frame(maxWidth: 120)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(palette.textDim)
            }
        }
    }

    private func courseName(_ id: String) -> String { Strings.courseTitle(id) }
    private func lessonCount(_ course: Course) -> Int {
        course.modules.reduce(0) { $0 + $1.lessons.count }
    }
}

/// Course detail — modules + lessons, with mastery + a lesson player.
struct CourseDetailView: View {
    @Environment(\.palette) private var palette
    @State private var progressStore = CourseProgressStore.shared
    @State private var activeLesson: Lesson?
    let course: Course

    var body: some View {
        List {
            ForEach(course.modules, id: \.id) { module in
                Section(moduleTitle(module.id)) {
                    ForEach(module.lessons, id: \.id) { lesson in
                        Button { activeLesson = lesson } label: {
                            HStack {
                                masteryIcon(progressStore.mastery(courseId: course.id, lessonId: lesson.id))
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
        }
        .navigationTitle(courseName(course.id))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeLesson) { lesson in
            NavigationStack { LessonPlayerView(course: course, lesson: lesson) }
        }
    }

    @ViewBuilder
    private func masteryIcon(_ m: MasteryLevel) -> some View {
        switch m {
        case .none: Image(systemName: "circle").foregroundStyle(palette.textDim)
        case .started: Image(systemName: "circle.lefthalf.filled").foregroundStyle(palette.primary)
        case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accentGreen)
        case .mastered: Image(systemName: "star.circle.fill").foregroundStyle(palette.accentGold)
        }
    }

    private func courseName(_ id: String) -> String { Strings.courseTitle(id) }
    private func moduleTitle(_ id: String) -> String { Strings.moduleTitle(id) }
    private func lessonTitle(_ id: String) -> String { Strings.lessonTitle(id) }
}
