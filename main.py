from server import mcp
import os

# Import tools so they get registered via decorators
import tools.csv_tools
import tools.parquet_tools


def main():
    print("Hello from mix-server! .. Starting server")
    transport = os.getenv("MCP_TRANSPORT", "stdio")
    mcp.run(transport=transport)


if __name__ == "__main__":
    main()
