// Full-screen video functionality

document.addEventListener('DOMContentLoaded', (): void => {
	const video = document.getElementById('fullscreen-video') as HTMLVideoElement | null;

	if (video) {
		video.addEventListener('play', (): void => {
			// For iOS Safari, use webkitEnterFullscreen if available.
			// Use type assertion to access webkit-specific methods
			const webkitVideo = video as any;

			if (webkitVideo.webkitEnterFullscreen) {
				webkitVideo.webkitEnterFullscreen();
			} else if (video.requestFullscreen) {
				video.requestFullscreen().catch((err: Error): void => {
					console.log('Failed to enable full screen mode:', err);
				});
			}
		});
	}
});
