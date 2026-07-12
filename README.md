# Swift: Docker Compose Parser

A Swift parser for Docker Compose files.

> [!IMPORTANT]
> This parser only supports the Compose file format as documented by Docker as of **Jul. 11, 2026**.

## Supported

- Multi-compose resolution:
  - `include`
  - `extends`
  - multi-file merge (equivalent to `-f` on the command line)
- Custom Compose merge tags: `!reset`, `!override`
- [Unique resources](https://docs.docker.com/reference/compose-file/merge/#unique-resources) during merge
- Automatically resolve all YAML environment variables, including `COMPOSE_PROJECT_NAME` as defined by the top-level `name` element
- Automatically resolve relative path to absolute.
- Support short syntax or long syntax, for example, for [`configs`](https://docs.docker.com/reference/compose-file/services/#configs) of the `services`.
- support list-form (`KEY=value`) or dictionary form (`KEY:value`), for example, for [`args`](https://docs.docker.com/reference/compose-file/build/#args) of `build`


## Not Supported

- Remote Compose files (e.g. git, OCI)
- Legacy Compose file normalization (e.g. deprecated `version` handling)




## Installation
 
### Xcode
 
File ▸ Add Package Dependencies… and enter the repository URL:
 
```
https://github.com/0Itsuki0/Swift_DockerComposeParser.git
```
 
Select a version rule (e.g. up to the next major version), then add `DockerComposeParser` to your target.
 
### Package.swift
 
Add it to your `Package.swift` file's dependencies:
 
```swift
dependencies: [
    .package(url: "https://github.com/0Itsuki0/Swift_DockerComposeParser.git", branch: "main")
]
```
 
Then add `DockerComposeParser` to your target's dependencies:
 
```swift
.target(
    name: "YourTarget",
    dependencies: ["DockerComposeParser"]
)
```

## Usage

Use the `ComposeParser.loadCompose` to load a single Compose file, or use `ComposeParser.loadComposes` to load multiple (similar to the `-f` on the command line).

**Returning:**

A DockerCompose object with the parsed resources where
- variables in the YAML resolved
- relative path resolved
- `include` resolved and merged
- `extends` resolved and merged
- any additional compose files (similar to the ones passed through the `-f` command) resolved and merged
 
```swift
import DockerComposeParser

// Load a single Compose file (handles include, extends, and env resolution)
let compose = try ComposeParser.loadCompose(
    composeURL,
    envFiles: [],
    projectDirectory: nil
)

// Load multiple Compose files, similar to `-f` on the command line
// order of the otherComposes will be the order of applying override, ie: the ones coming later has the highest priority
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
version: "3.8"
name: myapp
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    depends_on:
      - api
  api:
    build: ./api
    environment:
      - NODE_ENV=production
volumes:
  db-data:
networks:
  frontend:
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

```json
{
  "name" : "myapp",
  "networks" : {
    "frontend" : null
  },
  "volumes" : {
    "db-data" : null
  },
  "version" : "3.8",
  "services" : {
    "api" : {
      "build" : {
        "context" : ".\/api",
        "tags" : {
          "context" : null
        }
      },
      "environment" : {
        "NODE_ENV" : "production"
      }
    },
    "web" : {
      "image" : "nginx:latest",
      "ports" : [
        {
          "tags" : {
            "app_protocol" : null,
            "host_ip" : null,
            "name" : null,
            "mode" : null,
            "published" : null,
            "protocol" : null,
            "target" : null
          },
          "published" : "80",
          "target" : "80"
        }
      ],
      "depends_on" : {
        "api" : {
        }
      }
    }
  }
}
```
