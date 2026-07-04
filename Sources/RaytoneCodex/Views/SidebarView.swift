import SwiftUI

/// Codex-style left sidebar: top actions (新对话 / 搜索 / 插件 / 自动化), a 项目
/// section grouping threads under their project, and a 设置 footer.
struct SidebarView: View {
    @ObservedObject var store: SessionStore
    @State private var showSearch = false
    @State private var search = ""

    var body: some View {
        VStack(spacing: 0) {
            navSection
            if showSearch { searchField }
            projectList
            Hairline()
            footer
        }
        .frame(width: Theme.Layout.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.sidebar)
        .overlay(alignment: .trailing) { Hairline(axis: .vertical) }
    }

    // MARK: Top actions

    private var navSection: some View {
        VStack(spacing: 1) {
            SidebarNavRow(icon: "square.and.pencil", title: "新对话") {
                store.resetThread()
            }
            SidebarNavRow(icon: "magnifyingglass", title: "搜索", selected: showSearch) {
                withAnimation(.easeInOut(duration: 0.12)) { showSearch.toggle() }
                if !showSearch { search = "" }
            }
            SidebarNavRow(icon: "square.grid.2x2", title: "插件", selected: store.route == .plugins) {
                store.route = .plugins
            }
            SidebarNavRow(icon: "clock.arrow.circlepath", title: "自动化", selected: store.route == .automation) {
                store.route = .automation
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 36)
        .padding(.bottom, showSearch ? 4 : 8)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("搜索对话", text: $search)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 12)).foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 30)
        .background(Theme.fill)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: Project list

    private var projectList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 6) {
                    SectionLabel(text: "项目")
                    Spacer(minLength: 0)
                    Button {
                        Task { await store.refreshRuntimeThreads(searchTerm: trimmedSearch.isEmpty ? nil : trimmedSearch) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .buttonStyle(GhostIconButtonStyle(size: 20))
                    .help(store.runtimeThreadSyncStatusText)
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)

                ForEach(visibleProjects) { project in
                    ProjectGroup(store: store, project: project, threads: threads(in: project))
                }

                if visibleProjects.isEmpty {
                    Text("没有匹配“\(search)”的对话")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 0) {
            Button {
                store.route = .settings
                store.settingsPane = .general
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    Text("设置")
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 8)
                .frame(height: 30)
                .background(store.route == .settings ? Theme.fillSelected : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                store.route = .settings
                store.settingsPane = .computerControl
            } label: {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 14, weight: .regular))
            }
            .buttonStyle(GhostIconButtonStyle())
            .help("设备")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: Filtering

    private var trimmedSearch: String {
        search.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private var visibleProjects: [Project] {
        guard !trimmedSearch.isEmpty else { return store.projects }
        return store.projects.filter { !threads(in: $0).isEmpty || $0.name.lowercased().contains(trimmedSearch) }
    }

    private func threads(in project: Project) -> [ChatThread] {
        let all = store.threads
            .filter { $0.projectID == project.id }
            .sorted { $0.updatedAt > $1.updatedAt }
        guard !trimmedSearch.isEmpty else { return all }
        if project.name.lowercased().contains(trimmedSearch) { return all }
        return all.filter {
            $0.title.lowercased().contains(trimmedSearch) || $0.preview.lowercased().contains(trimmedSearch)
        }
    }
}

// MARK: - Nav row

private struct SidebarNavRow: View {
    let icon: String
    let title: String
    var selected: Bool = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(selected ? .primary : .secondary)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 30)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var rowBackground: Color {
        if selected { return Theme.fillSelected }
        return hovering ? Theme.fillHover : .clear
    }
}

// MARK: - Project group

private struct ProjectGroup: View {
    @ObservedObject var store: SessionStore
    let project: Project
    let threads: [ChatThread]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 7) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(project.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button {
                    store.newThread(in: project.id)
                } label: {
                    Image(systemName: "plus").font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(GhostIconButtonStyle(size: 20))
                .help("在 \(project.name) 新建对话")
            }
            .padding(.horizontal, 14)

            if threads.isEmpty {
                Text("暂无对话")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 33)
                    .padding(.vertical, 3)
            } else {
                VStack(spacing: 1) {
                    ForEach(threads) { thread in
                        SidebarThreadRow(
                            store: store,
                            thread: thread,
                            isSelected: store.selectedThreadID == thread.id
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

private struct SidebarThreadRow: View {
    @ObservedObject var store: SessionStore
    let thread: ChatThread
    let isSelected: Bool

    @State private var hovering = false

    var body: some View {
        Button {
            store.selectThread(thread)
        } label: {
            HStack(spacing: 8) {
                Text(thread.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? .primary : Color.primary.opacity(0.82))
                    .lineLimit(1)
                Spacer(minLength: 6)
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                } else {
                    Text(RelativeTime.short(thread.updatedAt))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, 25)
            .padding(.trailing, 9)
            .padding(.vertical, 6)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("删除对话", role: .destructive) {
                store.deleteThread(thread.id)
            }
        }
    }

    private var isWorking: Bool {
        thread.items.contains { item in
            if case let .command(run) = item.kind { return run.status == .running }
            return false
        }
    }

    private var rowBackground: Color {
        if isSelected { return Theme.fillSelected }
        return hovering ? Theme.fillHover : .clear
    }
}
