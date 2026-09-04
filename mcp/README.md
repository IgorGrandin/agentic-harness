# Shared capability registry

MCP and tool capabilities are independent from profiles. `registry.json` declares which profiles may use a capability and whether an implementation is external or only planned.

This directory does not contain fake servers, credentials, endpoints requiring secrets, or runtime session state. Runtime adapters may translate an explicitly configured capability into their native MCP format later. Profile permission never implies that a capability is installed, authenticated, or loaded into context.
