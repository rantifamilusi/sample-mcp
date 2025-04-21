from server import mcp

# Import tools so they get registered via decorators
import tools.csv_tools
import tools.parquet_tools


def main():
    print("Hello from mix-server! .. Starting server")
    mcp.run()


if __name__ == "__main__":
    main()
