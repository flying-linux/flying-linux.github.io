import os
block_devs = os.listdir("/sys/block")
for block in block_devs:
    path = os.readlink(os.path.join("/sys/block/", block))
    sysdir = os.path.join("/sys/block", path)
    print sysdir
    if os.path.exists(sysdir + "/queue/discard_granularity"):
        print open(sysdir+"/queue/discard_granularity").read()
    else:
        print block
