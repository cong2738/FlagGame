f = open("./image_code/파란점_빨간점.mem")
l = f.read().split()
red = "0xf800"
red_p = (0,0)
blue = "0x001f"
blue_p = (0,0)
for idx,pixel in enumerate(l):
    if pixel == red:
        red_p = (int(idx%320), int(idx/320))
    elif pixel == blue:
        blue_p = (int(idx%320), int(idx/320))

print("red:" + str(red_p) + ", blue: " + str(blue_p));
print(l[red_p[0] + red_p[1]*320], l[blue_p[0]+blue_p[1]*320])