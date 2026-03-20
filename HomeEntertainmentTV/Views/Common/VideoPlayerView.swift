import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    let fileId: Int?
    let startTime: Double

    @State private var player: AVPlayer
    @State private var hasAppliedInitialSeek = false
    @State private var timeObserver: Any?

    init(url: URL, fileId: Int? = nil, startTime: Double = 0) {
        self.url = url
        self.fileId = fileId
        self.startTime = startTime
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onAppear {
                configurePlayback()
            }
            .onDisappear {
                stopPlayback()
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
                guard notification.object as? AVPlayerItem === player.currentItem else { return }
                guard let fileId else { return }
                PlaybackProgressStore.clearMovieProgress(fileId: fileId)
            }
    }

    private func configurePlayback() {
        removeTimeObserverIfNeeded()

        let interval = CMTime(seconds: 15, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
            persistProgress()
        }

        if startTime > 0, !hasAppliedInitialSeek {
            hasAppliedInitialSeek = true
            let target = CMTime(seconds: startTime, preferredTimescale: 600)
            player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
    }

    private func stopPlayback() {
        persistProgress()
        removeTimeObserverIfNeeded()
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    private func persistProgress() {
        guard let fileId else { return }

        let positionSeconds = player.currentTime().seconds
        guard positionSeconds.isFinite, positionSeconds > 0 else { return }

        var durationSeconds = player.currentItem?.duration.seconds ?? 0
        if !durationSeconds.isFinite || durationSeconds <= 0 {
            durationSeconds = player.currentItem?.asset.duration.seconds ?? 0
        }

        guard durationSeconds.isFinite, durationSeconds > 0 else { return }

        PlaybackProgressStore.saveMovieProgress(
            fileId: fileId,
            positionSeconds: positionSeconds,
            durationSeconds: durationSeconds
        )
    }

    private func removeTimeObserverIfNeeded() {
        guard let timeObserver else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
}
