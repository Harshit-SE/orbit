from __future__ import annotations

import asyncio

from orbit_agent.connection import run_forever


def main() -> None:
    try:
        asyncio.run(run_forever())
    except KeyboardInterrupt:
        print("Orbit agent stopped.", flush=True)


if __name__ == "__main__":
    main()
