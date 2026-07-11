# Swift: Docker Compose Parser

A Swift parser for Docker Compose files.

> [!IMPORTANT]
> This parser only supports the Compose file format as documented by Docker as of **Jul. 11, 2026**.



## Usage

```swift
import DockerComposeParser

// Load a single Compose file (handles include, extends, and env resolution)
let compose = try ComposeParser.loadCompose(
    composeURL,
    envFiles: [],
    projectDirectory: nil
)

// Load multiple Compose files, similar to `-f` on the command line
let compose = try ComposeParser.loadComposes(
    composeURL,
    otherComposes: [overrideURL],
    envFiles: [],
    projectDirectory: nil
)
```

### Example

Given a `compose.yaml`:

```yaml
name: myapp

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    depends_on:
      db:
        required: true
    environment:
      - NODE_ENV=production
    volumes:
      - ./html:/usr/share/nginx/html:ro

  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: example
```

Loading it:

```swift
let compose = try ComposeParser.loadCompose(
    composeURL,
    envFiles: [],
    projectDirectory: nil
)
```

produces a `DockerCompose` whose relevant fields look like:

```swift
compose.name                                          // "myapp"

compose.services["web"]??.image                       // "nginx:latest"
compose.services["web"]??.ports?.first?.target         // "80"
compose.services["web"]??.ports?.first?.published      // "80"
compose.services["web"]??.environment?["NODE_ENV"]      // "production"
compose.services["web"]??.volumes?.first?.source        // "./html" (resolved to an absolute path)
compose.services["web"]??.volumes?.first?.target        // "/usr/share/nginx/html"
compose.services["web"]??.volumes?.first?.read_only     // true
compose.services["web"]??.depends_on?["db"]??.required  // true

compose.services["db"]??.image                          // "postgres:latest"
compose.services["db"]??.environment?["POSTGRES_PASSWORD"] // "example"
```

`ComposeParser` automatically:
- Resolves the `environment` list-form (`KEY=value`) into a `[String: String]` map
- Resolves relative paths (like `./html` above) to absolute paths based on the project directory
- Validates that every `depends_on` entry (here, `web`'s dependency on `db`) resolves to a service that actually exists — throwing otherwise

## Supported

- Multi-compose resolution:
  - `include`
  - `extends`
  - multi-file merge (equivalent to `-f` on the command line)
- Custom Compose merge tags: `!reset`, `!override`
- [Unique resources](https://docs.docker.com/reference/compose-file/merge/#unique-resources) during merge
- Resolving YAML environment variables, including `COMPOSE_PROJECT_NAME` as defined by the top-level `name` element

## Not Supported

- Remote Compose files (e.g. git, OCI)
- Legacy Compose file normalization (e.g. deprecated `version` handling)
