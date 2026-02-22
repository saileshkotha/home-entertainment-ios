import SwiftUI

struct TVView: View {
    @State private var vm = TVViewModel()
    @State private var showChannelPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Picker("Mode", selection: $vm.mode) {
                        ForEach(TVMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 8) {
                        Picker("Category", selection: $vm.selectedCategoryId) {
                            Text("All categories").tag("all")
                            ForEach(vm.channelCategories, id: \.id) { cat in
                                Text(cat.name).tag(String(cat.id))
                            }
                        }
                        .lineLimit(1)

                        if let channel = vm.selectedChannel {
                            Button {
                                showChannelPicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.caption2)
                                    Text(channel.name)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.tv, in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                ScrollView {
                    switch vm.mode {
                    case .live:
                        LiveContentView(vm: vm)
                    case .catchup:
                        CatchUpContentView(vm: vm)
                    }
                }
            }
            .navigationTitle("TV")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: "Search channels...")
            .onChange(of: vm.searchText) { _, _ in vm.filterChannels() }
            .onChange(of: vm.selectedCategoryId) { _, _ in vm.filterChannels() }
            .onChange(of: vm.mode) { _, newMode in
                if newMode == .catchup, vm.selectedChannel != nil {
                    vm.loadGuide()
                }
            }
            .sheet(isPresented: $showChannelPicker) {
                NavigationStack {
                    ChannelListView(vm: vm) {
                        showChannelPicker = false
                        if vm.mode == .catchup {
                            vm.loadGuide()
                        }
                    }
                    .navigationTitle("Select Channel")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showChannelPicker = false }
                        }
                    }
                }
                .presentationDetents([.large])
            }
        }
    }
}
