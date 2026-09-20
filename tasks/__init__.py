from invoke import Collection

import build
import distrobox

ns = Collection()
ns.add_collection(Collection.from_module(build))
ns.add_collection(Collection.from_module(distrobox))
