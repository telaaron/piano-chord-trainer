// Learn — lists the real courses (ALL_COURSES) → modules → lessons.
// M1: course list with completion at 0; lesson player lands M3.

import SwiftUI
import MusicEngine

extension Lesson: @retroactive Identifiable {}

struct LearnView: View {
    @Environment(\.palette) private var palette
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var progressStore = CourseProgressStore.shared
    private var isPad: Bool { hSize == .regular }

    /// The long path gets the red feature block; every other course is a row.
    private var featured: Course { ultimatePlanCourse }
    private var listed: [Course] { ALL_COURSES.filter { $0.id != featured.id } }
    private var totalLessons: Int { ALL_COURSES.reduce(0) { $0 + lessonCount($1) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(eyebrow: Strings.learnEyebrow(lessons: totalLessons),
                                title: CoachL10n.t("nav.learn"))
                NavigationLink { CourseDetailView(course: featured) } label: { featureBlock }
                    .buttonStyle(.plain)
                contents
                guides
            }
            .padding(.horizontal, isPad ? Theme.space6 : Theme.space4)
            .padding(.top, Theme.space3)
            .padding(.bottom, Theme.space6)
            .readableWidth(isPad ? 820 : 640)
        }
        .screenBackground()
    }

    private var featureBlock: some View {
        let done = completedLessons(featured)
        let total = lessonCount(featured)
        return FeatureBlock(eyebrow: Strings.pathEyebrow(lessons: total), ghost: "Δ7") {
            VStack(alignment: .leading, spacing: Theme.space3) {
                Text(courseName(featured.id))
                    .font(Display.serif(34, relativeTo: .title1))
                    .multilineTextAlignment(.leading)
                HStack(spacing: Theme.space2) {
                    ProgressView(value: Double(done), total: Double(max(total, 1)))
                        .tint(palette.onFeature)
                        .frame(maxWidth: 110)
                    Text(Strings.xOfY(done, total))
                        .font(.footnote.weight(.medium))
                }
            }
        }
    }

    /// The website's guide articles, readable offline (spec §4).
    private var guides: some View {
        let list = GuideLibrary.all(german: CoachL10n.isGerman)
        return VStack(alignment: .leading, spacing: Theme.space2) {
            EyebrowText(SettingsText.t("Guides", "Guides"))
                .padding(.leading, Theme.space4)
            TrackGroup {
                ForEach(Array(list.enumerated()), id: \.element.id) { index, guide in
                    NavigationLink { GuideView(guide: guide) } label: {
                        TrackRow(icon: "book.pages", title: guide.title,
                                 showsDivider: index < list.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// "INHALT" — numbered serif rows on a rule, no card background.
    private var contents: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowText(Strings.contents)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(palette.ink).frame(height: 1) }
            ForEach(Array(listed.enumerated()), id: \.element.id) { index, course in
                NavigationLink { CourseDetailView(course: course) } label: {
                    courseRow(course, number: index + 1, last: index == listed.count - 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func courseRow(_ course: Course, number: Int, last: Bool) -> some View {
        let done = completedLessons(course)
        let total = lessonCount(course)
        return HStack(alignment: .firstTextBaseline, spacing: Theme.space3) {
            Text(String(format: "%02d", number))
                .font(Display.serif(22, relativeTo: .title3))
                .foregroundStyle(palette.music)
                .frame(width: 36, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(courseName(course.id))
                    .font(Display.serif(24, relativeTo: .title3))
                    .foregroundStyle(palette.ink)
                Text("\(CoachL10n.plural("count.lessons", total)) · \(Strings.level(course.level))")
                    .font(.subheadline)
                    .foregroundStyle(palette.inkMuted)
            }
            Spacer(minLength: Theme.space2)
            status(done: done, total: total)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(palette.hairline).frame(height: 0.5) }
        }
    }

    @ViewBuilder
    private func status(done: Int, total: Int) -> some View {
        if done >= total, total > 0 {
            Text(Strings.done).font(.subheadline.weight(.semibold)).foregroundStyle(palette.music)
        } else if done > 0 {
            Text("\(done)/\(total)").font(.subheadline.monospacedDigit()).foregroundStyle(palette.inkMuted)
        } else {
            Text(Strings.new).font(.subheadline).foregroundStyle(palette.inkMuted)
        }
    }

    private func completedLessons(_ course: Course) -> Int {
        course.modules.flatMap(\.lessons).filter {
            let m = progressStore.mastery(courseId: course.id, lessonId: $0.id)
            return m == .completed || m == .mastered
        }.count
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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(eyebrow: Strings.level(course.level), title: courseName(course.id))
                ForEach(course.modules, id: \.id) { module in
                    VStack(alignment: .leading, spacing: Theme.space2) {
                        EyebrowText(moduleTitle(module.id))
                            .padding(.leading, Theme.space4)
                        TrackGroup {
                            ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                                Button { activeLesson = lesson } label: {
                                    HStack(spacing: 0) {
                                        TrackRow(number: String(format: "%02d", index + 1),
                                                 title: lessonTitle(lesson.id),
                                                 meta: CoachL10n.plural("count.steps", lesson.steps.count),
                                                 showsDivider: index < module.lessons.count - 1,
                                                 showsChevron: false)
                                        masteryIcon(progressStore.mastery(courseId: course.id, lessonId: lesson.id))
                                            .padding(.trailing, Theme.space4)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(Theme.space4)
            .readableWidth()
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $activeLesson) { lesson in
            NavigationStack { LessonPlayerView(course: course, lesson: lesson) }
        }
    }

    @ViewBuilder
    private func masteryIcon(_ m: MasteryLevel) -> some View {
        switch m {
        case .none: Image(systemName: "circle").foregroundStyle(palette.hairline)
        case .started: Image(systemName: "circle.lefthalf.filled").foregroundStyle(palette.music)
        case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.music)
        case .mastered: Image(systemName: "star.circle.fill").foregroundStyle(palette.music)
        }
    }

    private func courseName(_ id: String) -> String { Strings.courseTitle(id) }
    private func moduleTitle(_ id: String) -> String { Strings.moduleTitle(id) }
    private func lessonTitle(_ id: String) -> String { Strings.lessonTitle(id) }
}
