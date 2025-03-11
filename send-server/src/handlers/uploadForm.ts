import { checkBasicAuth } from '../helpers/auth';
import { Env } from '../types';

export async function handleUploadForm(request: Request, env: Env): Promise<Response> {
	const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Upload Form</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px; }
    .upload-container { max-width: 800px; margin: 0 auto; }
    .preview-container { display: flex; margin-top: 20px; gap: 10px; flex-wrap: wrap; }
    .preview-option { position: relative; cursor: pointer; border: 2px solid transparent; }
    .preview-option.selected { border: 2px solid #007bff; }
    .preview-option img { width: 160px; height: 90px; object-fit: cover; }
    .preview-option .timestamp { position: absolute; bottom: 0; right: 0; background: rgba(0,0,0,0.7); color: white; padding: 2px 5px; font-size: 12px; }
    .hidden { display: none; }
    .form-group { margin-bottom: 15px; }
    button { padding: 8px 16px; background-color: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer; }
    button:hover { background-color: #0056b3; }
    input[type="file"] { margin-bottom: 10px; }
    .preview-heading { margin-top: 20px; margin-bottom: 10px; }
  </style>
</head>
<body>
  <div class="upload-container">
    <h1>Upload File</h1>
    <form id="uploadForm" action="/upload" method="POST" enctype="multipart/form-data">
      <div class="form-group">
        <label for="file">Select a file:</label><br>
        <input type="file" id="file" name="file" required>
      </div>
      
      <div id="previewSection" class="hidden">
        <h3 class="preview-heading">Select a preview image:</h3>
        <div id="previewContainer" class="preview-container"></div>
      </div>
      
      <input type="hidden" id="previewDataInput" name="preview">
      
      <div class="form-group">
        <button type="submit" id="submitBtn">Upload File</button>
      </div>
    </form>
    <p><a href="/list">Go to file list</a></p>
  </div>

  <script>
    const fileInput = document.getElementById('file');
    const previewSection = document.getElementById('previewSection');
    const previewContainer = document.getElementById('previewContainer');
    const previewDataInput = document.getElementById('previewDataInput');
    const form = document.getElementById('uploadForm');
    
    let selectedPreviewBlob = null;
    
    fileInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
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
          previewOption.className = 'preview-option' + (index === 0 ? ' selected' : '');
          
          const img = document.createElement('img');
          img.src = URL.createObjectURL(frame.blob);
          
          const timestamp = document.createElement('div');
          timestamp.className = 'timestamp';
          timestamp.textContent = formatTime(frame.timestamp);
          
          previewOption.appendChild(img);
          previewOption.appendChild(timestamp);
          previewContainer.appendChild(previewOption);
          
          // Select this preview when clicked
          previewOption.addEventListener('click', () => {
            document.querySelectorAll('.preview-option').forEach(el => el.classList.remove('selected'));
            previewOption.classList.add('selected');
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
      
      const file = fileInput.files[0];
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
        console.log('No preview to add:', 
          'selectedPreviewBlob:', !!selectedPreviewBlob, 
          'file type:', file.type,
          'is video:', file.type.startsWith('video/')
        );
      }
      
      try {
        const response = await fetch('/upload', {
          method: 'POST',
          body: formData
        });
        
        if (response.ok) {
          const data = await response.json();
          window.location.href = '/file/' + data.key;
        } else {
          alert('Upload failed: ' + await response.text());
        }
      } catch (err) {
        alert('Upload error: ' + err.message);
      }
    });
    
    // Function to generate multiple preview frames from a video
    async function generateVideoFrames(videoFile, numFrames = 3) {
      return new Promise((resolve, reject) => {
        const video = document.createElement('video');
        video.autoplay = false;
        video.muted = true;
        video.src = URL.createObjectURL(videoFile);
        
        video.onloadedmetadata = () => {
          const frames = [];
          let framesProcessed = 0;
          
          // Calculate timestamps at different points in the video
          const timestamps = [];
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
            ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
            
            // Convert to blob
            canvas.toBlob((blob) => {
              frames.push({
                blob,
                timestamp: video.currentTime
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
            }, 'image/jpeg', 0.7);
          };
        };
        
        video.onerror = () => {
          URL.revokeObjectURL(video.src);
          reject(new Error('Error loading video'));
        };
      });
    }
    
    // Format seconds to MM:SS
    function formatTime(seconds) {
      const mins = Math.floor(seconds / 60);
      const secs = Math.floor(seconds % 60);
      return mins + ":" + secs.toString().padStart(2, "0");
    }
  </script>
</body>
</html>
  `;
	return new Response(html, { headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
}
