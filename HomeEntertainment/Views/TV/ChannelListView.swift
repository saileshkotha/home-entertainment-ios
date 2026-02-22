import SwiftUI

struct ChannelListView: View {
    @Bindable var vm: TVViewModel
    var onSelect: (() -> Void)?

    var body: some View {
        List(vm.filteredChannels, selection: Binding(
            get: { vm.selectedChannel?.id },
            set: { id in
                if let id, let channel = vm.filteredChannels.first(where: { $0.id == id }) {
                    vm.selectChannel(channel)
                    onSelect?()
                }
            }
        )) { channel in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(channel.genre.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if channel.hasArchive {
                    Text("Archive")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.purple, in: Capsule())
                }
            }
            .padding(.vertical, 2)
            .listRowBackground(
                channel.id == vm.selectedChannel?.id
                    ? Theme.accent.opacity(0.1)
                    : Color.clear
            )
            .contentShape(Rectangle())
            .onTapGesture {
                vm.selectChannel(channel)
                onSelect?()
            }
        }
        .listStyle(.plain)
    }
}
