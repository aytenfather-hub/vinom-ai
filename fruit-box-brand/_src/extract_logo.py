"""Cut the Fruit Box logo out of its white JPEG background without altering the artwork.
Background = white region connected to the image border (flood fill), so enclosed
whites (glass highlights, lettering) are untouched. Edge pixels get fractional alpha and
are un-mixed from white to avoid a white halo on dark backgrounds."""
from PIL import Image, ImageFilter
import numpy as np
from scipy import ndimage as ndi
SRC='01-logo/fruitbox-logo-original-source-767x717.jpg'
a=np.array(Image.open(SRC).convert('RGB')).astype(float)
mn=a.min(2); mx=a.max(2)
nearwhite=(mn>=232)&((mx-mn)<=18)
lab,_=ndi.label(nearwhite)
border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
bg=np.isin(lab,list(border))
fg=~bg
fg=ndi.binary_fill_holes(fg)          # keep any enclosed specks
# alpha: 1 inside, soft ramp in a 2px band next to the background
dist_in=ndi.distance_transform_edt(fg)
whiteness=(255-mn)/255.0             # 0 for pure white
soft=np.clip(whiteness/0.16,0,1)
alpha=np.where(dist_in>2.5,1.0,np.where(fg,np.maximum(soft,np.clip(dist_in/2.5,0,1)*soft+0.0),0))
alpha=np.where(fg&(dist_in>2.5),1.0,alpha)
# un-mix from white on semi-transparent pixels
A=alpha[...,None]
col=np.where(A>0.02,(a-(1-A)*255)/np.maximum(A,1e-3),a)
col=np.clip(col,0,255)
out=np.dstack([col,alpha*255]).astype(np.uint8)
im=Image.fromarray(out,'RGBA')
bbox=im.getbbox(); print('content bbox',bbox)
pad=12
x0,y0,x1,y1=bbox
crop=im.crop((x0-pad,y0-pad,x1+pad,y1+pad))
crop.save('01-logo/fruitbox-logo-original-transparent.png',optimize=True)
print('trimmed',crop.size)
# white-background original, trimmed & centered with clear space (the unchanged artwork)
w,h=crop.size

# --- remove tiny isolated JPEG specks (< 20 px) that are not part of the artwork
arr=np.array(crop).copy()
lab2,n=ndi.label(arr[...,3]>40)
sizes=ndi.sum(np.ones_like(lab2),lab2,range(1,n+1))
for i,sz in enumerate(sizes,1):
    if sz<20: arr[lab2==i,3]=0
crop=Image.fromarray(arr,'RGBA'); crop.save('01-logo/fruitbox-logo-original-transparent.png',optimize=True)

# --- white-background master (artwork untouched, extra clear space)
W,H=crop.size; p=int(H*0.17)
wb=Image.new('RGBA',(W+2*p,H+2*p),(255,255,255,255)); wb.alpha_composite(crop,(p,p))
wb.convert('RGB').save('01-logo/fruitbox-logo-original-white-bg.png',optimize=True)

# --- 2x interpolated copy (Lanczos). No new detail is created: convenience only.
crop.resize((W*2,H*2),Image.LANCZOS).save('01-logo/fruitbox-logo-original-transparent@2x-interpolated.png',optimize=True)

# --- dark-background version: same artwork + cream "sticker" outline so the dark ribbon
#     edges separate from dark surfaces. Outline is added around, the drawing is not changed.
def outlined(img,r,color):
    a=np.array(img)[...,3]>60
    yy,xx=np.mgrid[-r:r+1,-r:r+1]; disk=(xx**2+yy**2)<=r*r
    pad=r+4
    a=np.pad(a,pad)
    d=ndi.binary_dilation(a,structure=disk)
    d=ndi.binary_fill_holes(d)
    m=Image.fromarray((d*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    base=Image.new('RGBA',m.size,color+(0,)); base.putalpha(m)
    base.alpha_composite(img,(pad,pad)); return base
dark=outlined(crop,9,(253,248,243))
dark.save('01-logo/fruitbox-logo-dark-bg-version-transparent.png',optimize=True)
prev=Image.new('RGBA',(dark.width+2*p,dark.height+2*p),(96,39,19,255)); prev.alpha_composite(dark,(p,p))
prev.convert('RGB').save('01-logo/preview-dark-bg-version-on-cocoa.png')
print('done',crop.size,dark.size)
