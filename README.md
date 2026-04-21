# sample-mcp

This project provides a simple MCP server with tools that summarize CSV and Parquet files.

## Containerization

The app is containerized with two build variants:

- Primary app image: multi-stage Docker build using Docker Hub `python:3.12-slim`
- Alternate DHI app image: multi-stage Docker build using `dhi.io/python:3.13`

### Files added

- `Dockerfile`: single multi-stage image build with overridable builder/runtime base image args.
- `compose.yaml`: launches the app.
- `.dockerignore`: reduces Docker build context size.
- `scripts/compose-up-and-scout.sh`: launches app and runs Docker Scout CVE scan from host context.

## Run with Docker Compose

From the project root:

```bash
./scripts/compose-up-and-scout.sh
```

This will:

1. Build `sample-mcp:latest`
2. Build `sample-mcp-dhi:latest`
3. Start both `app` and `app-dhi` services
4. Run Docker Scout scans for both images
5. Print a vulnerability comparison table (Critical/High/Medium/Low/Unknown)

To run app-only with Compose:

```bash
docker compose up --build -d
```

To run the DHI-based service:

```bash
docker compose up --build -d app-dhi
```

To run both services together:

```bash
docker compose up --build -d app app-dhi
```

Service ports:

- `app` (Docker Hub args in shared Dockerfile): `8000:8000`
- `app-dhi` (DHI args in shared Dockerfile): `8001:8000`

To run Scout scan manually:

```bash
docker scout cves sample-mcp:latest
docker scout cves sample-mcp-dhi:latest
```

To stop everything:

```bash
docker compose down
```

## Notes

- Scan-on-launch intentionally uses host Docker Scout context so Docker Desktop login/session is reused.
- Why not a `scout-scan` Compose service: your Docker config uses `credsStore: desktop`, which works on host but is not available inside Linux containers.
- `mcp.run()` defaults to `stdio`, which exits in detached containers; Compose sets `MCP_TRANSPORT=streamable-http` so the app stays running.
- DHI tags verified here: `dhi.io/python:3.13` and `dhi.io/python:3.12` are available.
- `dhi.io/python:3.13-slim` (and `3.12-slim`) did not resolve in this environment.
