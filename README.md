#  Swift: Docker Compose Parser


Only supporting compose file format as per docker documentation as of Jul.11th.2026.


usage:

ComposeParser.loadComposes
ComposeParser.loadCompose



Supported
- multi-compose (includes, extensions, merge as of -f in command line) with custom compose tag handling (!reset, !override), unique resources (https://docs.docker.com/reference/compose-file/merge/#unique-resources) 
- resolving yaml env (including the COMPOSE_PROJECT_NAME defined by the name top level element)


Not supported
- remote compose file
- legacy compose normalization
