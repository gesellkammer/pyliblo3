#!/usr/bin/env python3
import os
import argparse
import sys
from pathlib import Path
import logging

try:
    import pyliblo3 as liblo
    from emlib import doctools
except ImportError:
    import textwrap
    msg = ("**WARNING**: Trying to update documentation, but the python present in the current environment"
           " does not have the needed packages (pyliblo3, emlib). Documentation will not be"
           " updated")
    print()
    print("\n".join(textwrap.wrap(msg, width=72)))
    print()
    sys.exit(0)

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
    config = doctools.RenderConfig(splitName=True, includeInheritedMethods=False, )
    modules = {'liblo': liblo._liblo}
    for name, module in modules.items():
        docs = doctools.generateDocsForModule(module,
                                              renderConfig=config,
                                              title=name,
                                              includeCustomExceptions=False)
        open(dest/f"{name}.md", "w").write(docs)
    
    
if __name__ == "__main__":
    root = findRoot()
    docsfolder = root / "docs"
    print("Documentation folder", docsfolder)
    logging.basicConfig(level="DEBUG")
    doctools.logger.setLevel("DEBUG")
    assert docsfolder.exists()
    main(docsfolder)
    os.chdir(root)
    os.system("mkdocs build")
