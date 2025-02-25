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
    .upload-container { max-width: 600px; margin: 0 auto; }
  </style>
</head>
<body>
  <div class="upload-container">
    <h1>Upload File</h1>
    <form action="/upload" method="POST" enctype="multipart/form-data">
      <input type="file" name="file" required>
      <br/>
      <button type="submit">Upload File</button>
    </form>
    <p><a href="/list">Go to file list</a></p>
  </div>
</body>
</html>
  `;
	return new Response(html, { headers: { 'Content-Type': 'text/html;charset=UTF-8' } });
}
