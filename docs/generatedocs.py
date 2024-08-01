#!/usr/bin/env python3
import os
import argparse
import sys
from pathlib import Path
import logging
import shutil

try:
    import pyliblo3 as liblo
    from emlib import doctools
except ImportError:
    import textwrap
    print("\n**WARNING**: Failed to update documentation. The python present in the current environment"
           " does not have the needed packages (pyliblo3, emlib)\n")
    sys.exit(1)


def findRoot():
    p = Path(__file__).parent
    if (p.parent/"setup.py").exists():
        return p.parent
    if (p/"index.md").exists():
        return p.parent
    if (p/"setup.py").exists():
        return p
    raise RuntimeError(f"Could not locate the root folder, search started at {p}")
    

def main(dest: Path):
    config = doctools.RenderConfig(splitName=True, includeInheritedMethods=False)
    markdown = doctools.generateDocsForModule(liblo._liblo, renderConfig=config, title='Reference', includeCustomExceptions=False)
    open(dest/"Reference.md", "w").write(markdown)

    
if __name__ == "__main__":
    logging.basicConfig(level="DEBUG")
    doctools.logger.setLevel("DEBUG")
    root = findRoot()
    docsfolder = root / "docs"
    print("Documentation folder", docsfolder)
    assert docsfolder.exists()
    main(docsfolder)

    if not shutil.which('mkdocs'):
        print("\n**WARNING**: mkdocs not found, cannot generate HTML docs")
    else:
        os.chdir(root)
        os.system("mkdocs build")
