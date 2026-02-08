from pathlib import Path

ROOT_DIR = Path(Path(__file__).parent / "..").absolute()
BUILD_DIR = Path(ROOT_DIR / "build")
CACHE_DIR = Path(ROOT_DIR / "cache")
DIST_DIR = Path(ROOT_DIR / "dist")
TEST_DIR = Path(ROOT_DIR / "test")
