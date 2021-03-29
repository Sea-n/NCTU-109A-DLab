from PIL import Image
from sys import argv

if len(argv) == 1:
    print("Usage: %s file1.ppm [file2.png file3.gif ...]" % argv[0])
    quit()

for arg in argv[1:]:
    ext  = arg[-4:]
    name = arg[:-4]

    im = Image.open(arg, 'r')
    mem = open(name + '.mem', 'w')

    if (ext == '.ppm'):
        pix_val = list(im.getdata())
        for pix in pix_val:
             if pix == (0, 0, 0):
                 mem.write("0f0\n")
             else:
                 mem.write("%1x%1x%1x\n" % (pix[0]>>4, pix[1]>>4,  pix[2]>>4))

    elif (ext == '.png'):
        pix_val = list(im.getdata())
        for pix in pix_val:
            if pix[3] == 0:
                mem.write("0f0\n")
            else:
                mem.write("%1x%1x%1x\n" % (pix[0]>>4, pix[1]>>4, pix[2]>>4))

    elif (ext == '.gif'):
        try:
            while True:
                pix_val = list(im.convert('RGBA').getdata())
                for pix in pix_val:
                    if pix[3] == 0:
                        mem.write("0f0\n")
                    else:
                        mem.write("%1x%1x%1x\n" % (pix[0]>>4, pix[1]>>4, pix[2]>>4))
                im.seek(im.tell() + 1)
        except EOFError:
            pass

    else:
        print('Unsupported file type %s' % ext)

    mem.close()
