# Send Files - Cloudflare Workers File Sharing Service

This is a file sharing service built on Cloudflare Workers, allowing you to upload, share, and manage files through a simple web interface. The service uses Cloudflare R2 for storage, D1 for database, and Durable Objects for access counting.

## Prerequisites

- [Node.js](https://nodejs.org/) (v16 or later)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/) (Cloudflare Workers CLI)
- A Cloudflare account with Workers, R2, D1, and KV access

## Setup Instructions

1. **Clone this repository**

```bash
git clone <repository-url>
cd server
```

2. **Install dependencies**

```bash
npm install
```

3. **Customize the configuration**

The project has been updated to use dynamic hostname detection, so it will automatically use your workers.dev subdomain or custom domain without hardcoding.

## Customization Steps

### 1. Update wrangler.toml

The `wrangler.toml` file contains the configuration for your Cloudflare Workers project. You need to update it with your own Cloudflare account details:

```toml
name = "your-project-name"           # Change to your preferred project name
account_id = "your-account-id"        # Your Cloudflare account ID
workers_dev = true                    # Keep true to use workers.dev subdomain
# For custom domain (optional):
# routes = [{ pattern = "your-domain.com", custom_domain = true }]
```

### 2. Create required Cloudflare resources

#### R2 Bucket

Create an R2 bucket for file storage:

```bash
wrangler r2 bucket create your-bucket-name
```

Then update the `wrangler.toml` file:

```toml
[[r2_buckets]]
binding = "R2_BUCKET"
bucket_name = "your-bucket-name"     # The name you chose for your bucket
```

#### D1 Database

Create a D1 database:

```bash
wrangler d1 create your-database-name
```

This will output a database ID. Update the `wrangler.toml` file:

```toml
[[d1_databases]]
binding = "DB"
database_name = "your-database-name"  # The name you chose for your database
database_id = "your-database-id"      # The ID from the create command
```

Initialize the database with the schema:

```bash
wrangler d1 execute your-database-name --file=schema.sql
```

#### KV Namespace

Create a KV namespace for rate limiting:

```bash
wrangler kv:namespace create "RATE_LIMIT"
```

This will output a namespace ID. Update the `wrangler.toml` file:

```toml
[[kv_namespaces]]
binding = "RATE_LIMIT"
id = "your-namespace-id"              # The ID from the create command
```

### 3. Configure Authentication (Optional)

The service uses basic authentication for upload and management functions. You can set your username and password by adding environment variables:

```bash
wrangler secret put AUTH_USERNAME
# Enter your desired username when prompted

wrangler secret put AUTH_PASSWORD
# Enter your desired password when prompted
```

## Deployment

Deploy your service to Cloudflare Workers:

```bash
npm run deploy
```

Or manually with:

```bash
wrangler deploy
```

After deployment, your service will be available at:
- `https://your-project-name.your-account.workers.dev` (if using workers.dev subdomain)
- `https://your-domain.com` (if using a custom domain)

## Using a Custom Domain (Optional)

If you want to use a custom domain instead of the workers.dev subdomain:

1. Add your domain to Cloudflare (if not already there)
2. Uncomment and update the routes section in `wrangler.toml`:
   ```toml
   routes = [{ pattern = "your-domain.com", custom_domain = true }]
   ```
3. Set `workers_dev = false` to disable the workers.dev subdomain
4. Deploy again with `wrangler deploy`

## Features

- File upload and sharing
- Video preview generation
- Access counting (limited to 100 views per file)
- Basic authentication for upload and management
- Responsive design
- Social media preview metadata

## Troubleshooting

- **Deployment Issues**: Make sure your Cloudflare account has the necessary permissions and subscriptions for Workers, R2, D1, and KV.
- **Database Errors**: Verify that your D1 database was created and initialized with the schema.
- **Storage Errors**: Check that your R2 bucket was created correctly and the binding in wrangler.toml matches.
- **Authentication Issues**: If you've set AUTH_USERNAME and AUTH_PASSWORD secrets, make sure they're correctly configured.

## License

[MIT License](LICENSE)
