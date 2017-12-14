import os
block_devs = os.listdir("/sys/block")
for block in block_devs:
    path = os.readlink(os.path.join("/sys/block/", block))
    sysdir = os.path.join("/sys/block", path)
    print sysdir
    if os.path.exists(sysdir + "/removable"):
        print open(sysdir+"/removable").read()
    else:
        print block
