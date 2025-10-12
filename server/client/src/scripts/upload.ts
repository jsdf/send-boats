const fileInput = document.getElementById('file') as HTMLInputElement;
const previewSection = document.getElementById('previewSection') as HTMLDivElement;
const previewContainer = document.getElementById('previewContainer') as HTMLDivElement;
const previewDataInput = document.getElementById('previewDataInput') as HTMLInputElement;
const form = document.getElementById('uploadForm') as HTMLFormElement;
const submitBtn = document.getElementById('submitBtn') as HTMLButtonElement;

let selectedPreviewBlob: Blob | null = null;

console.log('Upload script loaded');

// Disable submit button until a file is selected
submitBtn.disabled = true;

interface VideoPreviewFrame {
	blob: Blob;
	timestamp: number;
}

fileInput.addEventListener('change', async (e) => {
	const target = e.target as HTMLInputElement;
	const file = target.files?.[0];

	// Enable/disable submit button based on file selection
	submitBtn.disabled = !file;

	if (!file) return;

	// Clear previous previews
	previewContainer.innerHTML = '';
	previewSection.classList.add('hidden');
	previewDataInput.value = '';

	// Only generate previews for video files
	if (!file.type.startsWith('video/')) return;

	try {
		// Generate multiple preview frames
		const frames = await generateVideoFrames(file, 3);

		frames.forEach((frame, index) => {
			const previewOption = document.createElement('div');
			previewOption.className = `relative cursor-pointer border-2 rounded-lg overflow-hidden transition-all ${
				index === 0
					? 'border-primary ring-2 ring-primary ring-opacity-30'
					: 'border-transparent hover:border-base-content hover:border-opacity-20'
			}`;

			const img = document.createElement('img');
			img.src = URL.createObjectURL(frame.blob);
			img.className = 'w-full h-auto object-cover';

			const timestamp = document.createElement('div');
			timestamp.className = 'absolute bottom-0 right-0 bg-base-300 bg-opacity-90 px-2 py-1 text-xs rounded-tl';
			timestamp.textContent = formatTime(frame.timestamp);

			previewOption.appendChild(img);
			previewOption.appendChild(timestamp);
			previewContainer.appendChild(previewOption);

			// Select this preview when clicked
			previewOption.addEventListener('click', () => {
				document.querySelectorAll('#previewContainer > div').forEach((el) => {
					el.className = el.className.replace('border-primary ring-2 ring-primary ring-opacity-30', 'border-transparent');
				});
				previewOption.className = previewOption.className.replace(
					'border-transparent',
					'border-primary ring-2 ring-primary ring-opacity-30'
				);
				selectedPreviewBlob = frame.blob;
			});

			// Select the first frame by default
			if (index === 0) {
				selectedPreviewBlob = frame.blob;
			}
		});

		previewSection.classList.remove('hidden');
	} catch (err) {
		console.error('Error generating previews:', err);
	}
});

form.addEventListener('submit', async (e) => {
	e.preventDefault();

	const file = fileInput.files?.[0];
	if (!file) return;

	const formData = new FormData();
	formData.append('file', file);

	// If we have a selected preview and it's a video, add the preview
	if (selectedPreviewBlob && file.type.startsWith('video/')) {
		console.log('Adding preview to form data, size:', selectedPreviewBlob.size);
		const previewFile = new File([selectedPreviewBlob], 'preview.jpg', { type: 'image/jpeg' });
		formData.append('preview', previewFile);

		// Debug: Check if the preview is actually in the FormData
		console.log('FormData entries:');
		for (const entry of formData.entries()) {
			console.log(entry[0], ':', entry[1]);
		}
	} else {
		console.log(
			'No preview to add:',
			'selectedPreviewBlob:',
			!!selectedPreviewBlob,
			'file type:',
			file.type,
			'is video:',
			file.type.startsWith('video/')
		);
	}

	try {
		const response = await fetch('/upload', {
			method: 'POST',
			body: formData,
		});

		if (response.ok) {
			const data = await response.json();
			window.location.href = '/file/' + data.key;
		} else {
			alert('Upload failed: ' + (await response.text()));
		}
	} catch (err) {
		alert('Upload error: ' + (err as Error).message);
	}
});

// Function to generate multiple preview frames from a video
async function generateVideoFrames(videoFile: File, numFrames: number = 3): Promise<VideoPreviewFrame[]> {
	return new Promise((resolve, reject) => {
		const video = document.createElement('video');
		video.autoplay = false;
		video.muted = true;
		video.src = URL.createObjectURL(videoFile);

		video.onloadedmetadata = () => {
			const frames: VideoPreviewFrame[] = [];
			let framesProcessed = 0;

			// Calculate timestamps at different points in the video
			const timestamps: number[] = [];
			for (let i = 0; i < numFrames; i++) {
				// Distribute frames across the video duration
				// Skip the very beginning and end
				const percentage = (i + 1) / (numFrames + 1);
				timestamps.push(video.duration * percentage);
			}

			// Process each timestamp
			video.currentTime = timestamps[0];

			video.onseeked = () => {
				// Create canvas and draw video frame
				const canvas = document.createElement('canvas');
				canvas.width = video.videoWidth;
				canvas.height = video.videoHeight;
				const ctx = canvas.getContext('2d');
				if (!ctx) {
					reject(new Error('Could not get canvas context'));
					return;
				}
				ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

				// Convert to blob
				canvas.toBlob(
					(blob) => {
						if (!blob) {
							reject(new Error('Could not create blob'));
							return;
						}

						frames.push({
							blob,
							timestamp: video.currentTime,
						});

						framesProcessed++;

						// When all frames are processed
						if (framesProcessed === numFrames) {
							URL.revokeObjectURL(video.src);
							resolve(frames);
						} else {
							// Move to next timestamp
							video.currentTime = timestamps[framesProcessed];
						}
					},
					'image/jpeg',
					0.7
				);
			};
		};

		video.onerror = () => {
			URL.revokeObjectURL(video.src);
			reject(new Error('Error loading video'));
		};
	});
}

// Format seconds to MM:SS
function formatTime(seconds: number): string {
	const mins = Math.floor(seconds / 60);
	const secs = Math.floor(seconds % 60);
	return mins + ':' + secs.toString().padStart(2, '0');
}
