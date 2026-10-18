"""Pack complete painted figures without assuming equally spaced source rows.

Only segmentation, cropping, uniform whole-figure scaling and atlas alignment.
No body-part warping, recoloring, or synthetic walk frames.
"""
from pathlib import Path
import json
import heapq
import numpy as np
from scipy import ndimage
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art-source/v13'
DEST=ROOT/'assets/characters'

def split_touching(mask,seeds):
    """Constrained multi-source flood; narrow accidental joins are costly."""
    distance=ndimage.distance_transform_edt(mask)
    penalty=1+(6/np.maximum(distance,.4))**4
    costs=np.full(mask.shape,np.inf);regions=np.zeros(mask.shape,dtype='int32');queue=[]
    for y,x in zip(*np.where(seeds>0)):
        marker=int(seeds[y,x]);costs[y,x]=0;regions[y,x]=marker;heapq.heappush(queue,(0,y,x,marker))
    height,width=mask.shape
    while queue:
        cost,y,x,marker=heapq.heappop(queue)
        if cost>costs[y,x]:continue
        for dy,dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny,nx=y+dy,x+dx
            if not (0<=ny<height and 0<=nx<width) or not mask[ny,nx]:continue
            new_cost=cost+(penalty[y,x]+penalty[ny,nx])*.5
            if new_cost<costs[ny,nx]:
                costs[ny,nx]=new_cost;regions[ny,nx]=marker;heapq.heappush(queue,(new_cost,ny,nx,marker))
    return regions

def figures(path,rows,columns=5):
    source=Image.open(path).convert('RGBA');alpha=np.asarray(source.getchannel('A'))
    labels,count=ndimage.label(alpha>100)
    def collect():
        groups=[[] for i in range(columns)]
        for index,box in enumerate(ndimage.find_objects(labels),1):
            if box is None:continue
            ys,xs=box;h=ys.stop-ys.start;w=xs.stop-xs.start
            area=int(np.count_nonzero(labels[box]==index))
            if h<source.height/rows*.35 or w<20 or area<500:continue
            head=(labels[ys.start:ys.start+max(2,round(h*.15)),xs]==index)
            _,xx=np.where(head)
            center=xs.start+float(xx.mean())
            column=min(columns-1,max(0,int(center/source.width*columns)))
            groups[column].append((area,ys.start,index,box))
        return groups
    groups=collect()
    complete=[sorted(sorted(g,reverse=True)[:rows],key=lambda v:v[1]) for g in groups if len(g)>=rows]
    if complete and any(len(g)<rows for g in groups):
        # Occasionally a boot's antialias touches the next row's hair by one
        # pixel. Seed their torsos, then split at the narrow connection rather
        # than cutting both figures along an assumed horizontal grid line.
        centers=np.median([[v[3][0].start+(v[3][0].stop-v[3][0].start)*.42 for v in g] for g in complete],axis=0)
        typical=float(np.median([v[3][0].stop-v[3][0].start for g in complete for v in g]))
        for col,g in enumerate(groups):
            if len(g)>=rows:continue
            for area,top,index,box in g:
                ys,xs=box
                if ys.stop-ys.start<typical*1.45:continue
                targets=[y for y in centers if ys.start<y<ys.stop]
                if len(targets)<2:continue
                mask=labels[box]==index;yy,xx=np.where(mask)
                seeds=np.zeros(mask.shape,dtype='int32')
                for i,y in enumerate(targets,1):
                    seed=np.argmin((yy+ys.start-y)**2+(xx+xs.start-(col+.5)*source.width/columns)**2)
                    seeds[yy[seed],xx[seed]]=i
                regions=split_touching(mask,seeds)
                section=labels[box]
                for i in range(1,len(targets)+1):
                    if i==1:new_index=index
                    else:count+=1;new_index=count
                    section[mask & (regions==i)]=new_index
        groups=collect()
    result=[[None for col in range(columns)] for row in range(rows)]
    for col,candidates in enumerate(groups):
        if len(candidates)<rows:raise ValueError((path,col,'missing complete figures',len(candidates),rows))
        selected=sorted(sorted(candidates,reverse=True)[:rows],key=lambda item:item[1])
        for row,(_,top,index,box) in enumerate(selected):
            ys,xs=box
            bounds=(max(0,xs.start-2),max(0,ys.start-2),min(source.width,xs.stop+2),min(source.height,ys.stop+2))
            crop=source.crop(bounds)
            component=ndimage.binary_dilation(labels[bounds[1]:bounds[3],bounds[0]:bounds[2]]==index,iterations=1)
            channel=np.asarray(crop.getchannel('A'))*component
            crop.putalpha(Image.fromarray(channel.astype('uint8')))
            result[row][col]=crop
    for row in result:
        heights=[crop.height for crop in row]
        if max(heights)>np.median(heights)*1.3:raise ValueError((path,'a figure includes a neighbouring row',heights))
    return result

def pack(actor,rows,width=280,clips=None,revision=13):
    rows=[list(angles) for angles in rows]
    frame_mirror=[[False]*5 for angles in rows]
    normalized_pairs=[];normalized_columns=[4]
    if actor in ['ivan','ivan_masked','commander','commander_masked'] and len(rows)==3:normalized_pairs=[(1,2)]
    if revision>=14:
        normalized_columns=[0,4]
        if actor in ['ivan_combat','ivan_masked_combat']:normalized_pairs=[(3,4),(5,6)]
    if normalized_pairs:
        def bias(crop):
            mask=np.asarray(crop.getchannel('A'))>100
            _,head=np.where(mask[:round(crop.height*.15)])
            _,toe=np.where(mask[-round(crop.height*.045):])
            return float(toe.mean()-head.mean())
        for a,b in normalized_pairs:
            for column in normalized_columns:
                if bias(rows[a][column])*bias(rows[b][column])>0:
                    # Symmetric straight-on outfits can reuse one COMPLETE
                    # pose with a renderer mirror. No isolated limb is warped.
                    # The veteran's asymmetric satchel is never gait-mirrored.
                    chosen=b if revision==13 or abs(bias(rows[b][column]))>=abs(bias(rows[a][column])) else a
                    other=a if chosen==b else b
                    rows[other][column]=rows[chosen][column];frame_mirror[other][column]=True
    atlas=Image.new('RGBA',(5*width,352*len(rows)))
    metrics=[];samples=[]
    for row,angles in enumerate(rows):
        for col,crop in enumerate(angles):
            alpha=np.asarray(crop.getchannel('A'))
            _,xx=np.where(alpha[:max(2,round(crop.height*.15))]>100)
            scale=324/crop.height
            tile=crop.resize((round(crop.width*scale),324),Image.Resampling.LANCZOS)
            x=round(width/2-float(xx.mean())*scale)
            if x<2 or x+tile.width>width-2:raise ValueError((actor,row,col,'figure clips',x,tile.size,width))
            atlas.alpha_composite(tile,(col*width+x,row*352+18))
            pixels=np.asarray(tile);mask=pixels[:,:,3]>180
            center=width/2-x
            patch=pixels[90:165,max(0,round(center-25)):min(tile.width,round(center+25)),:3]/255.0
            occupied=mask[90:165,max(0,round(center-25)):min(tile.width,round(center+25))]
            linear=np.where(patch<=.04045,patch/12.92,((patch+.055)/1.055)**2.4)
            luma=linear@np.array([.2126,.7152,.0722])
            value=float(np.median(luma[occupied])) if occupied.any() else .1
            # A rifle or a swinging sleeve can change one coat patch without
            # changing exposure. Use the common shift across four body regions,
            # so compensating the coat never makes an unchanged face flash.
            region_values=[]
            for start,end in [(4,65),(90,165),(180,245),(265,320)]:
                region=pixels[start:end,max(0,round(center-58)):min(tile.width,round(center+58)),:3]/255.0
                solid=mask[start:end,max(0,round(center-58)):min(tile.width,round(center+58))]
                region_linear=np.where(region<=.04045,region/12.92,((region+.055)/1.055)**2.4)
                values=region_linear@np.array([.2126,.7152,.0722])
                region_values.append(float(np.median(values[solid])) if solid.any() else .1)
            if col==0:samples.append([])
            samples[-1].append(region_values)
            _,toe=np.where(mask[-15:])
            metrics.append({'row':row,'column':col,'source_size':list(crop.size),'packed_size':list(tile.size),'anchor_x':x,'coat_luminance':value,'region_luminance':region_values,'toe_bias':round(float(toe.mean())-center,3)})
    atlas.save(DEST/(actor+'.png'),optimize=True)
    if not actor.endswith('_combat'):
        front=rows[0][0]
        bust=front.crop((0,0,front.width,round(front.height*.43)))
        _,head_x=np.where(np.asarray(front.getchannel('A'))[:round(front.height*.15)]>100)
        scale=238/bust.height
        bust=bust.resize((round(bust.width*scale),238),Image.Resampling.LANCZOS)
        portrait=Image.new('RGBA',(240,280))
        portrait.alpha_composite(bust,(round(120-head_x.mean()*scale),42))
        portrait.save(ROOT/'assets/portraits'/(actor+'.png'),optimize=True)
    manifest=json.loads((DEST/'atlas.json').read_text())
    target=np.median(np.array(samples),axis=0)
    exposure=np.clip(np.exp(np.median(np.log(target/np.maximum(.003,np.array(samples))),axis=2)),.88,1.12)
    manifest[actor]={'file':actor+'.png','directions':8,'source_angles':5,'poses':len(rows),'cell':[width,352],'baseline':342,'body_pixels':324,'rear_diagonal_normalized':True,'clips':clips or ['idle','walk_left','walk_right'][:len(rows)],'packing_revision':revision,'exposure':np.round(exposure,5).tolist(),'frame_mirror':frame_mirror}
    (DEST/'atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    return metrics

def main():
    report={}
    if (SOURCE/'ivan_base_source.png').exists():
        report['ivan']=pack('ivan',figures(SOURCE/'ivan_base_source.png',3))
    if (SOURCE/'static_cast.png').exists():
        source=figures(SOURCE/'static_cast.png',4)
        for i,actor in enumerate(['commune_moro','commune_cook','sech_cook','commune_child']):report[actor]=pack(actor,[source[i]],clips=['idle'])
    for actor in ['commander','commander_masked','ivan_masked']:
        if (SOURCE/(actor+'.png')).exists():report[actor]=pack(actor,figures(SOURCE/(actor+'.png'),3))
    if (SOURCE/'sech_cast.png').exists():
        source=figures(SOURCE/'sech_cast.png',2)
        for i,actor in enumerate(['sech_elder','sergey']):report[actor]=pack(actor,[source[i]],clips=['idle'])
    if (SOURCE/'veteran_normal.png').exists():
        source=figures(SOURCE/'veteran_normal.png',1)
        report['veteran_masked']=pack('veteran_masked',source,clips=['idle'])
    for actor in ['veteran_masked','ivan_masked','ivan']:
        ready=SOURCE/(actor+'_ready.png');reload=SOURCE/(actor+'_reload.png')
        if ready.exists() and reload.exists():source=figures(ready,3)+figures(reload,3)
        elif actor=='veteran_masked' and (SOURCE/(actor+'_combat.png')).exists():source=figures(SOURCE/(actor+'_combat.png'),6)
        elif actor=='ivan' and (SOURCE/'ivan_combat.png').exists():source=figures(SOURCE/'ivan_combat.png',6)
        else:continue
        left=SOURCE/(actor+'_left.png')
        if left.exists():
            corrected=figures(left,2);source[1]=corrected[0];source[4]=corrected[1]
        if actor=='veteran_masked' and (SOURCE/'veteran_rear.png').exists():
            rear=figures(SOURCE/'veteran_rear.png',1,6)[0]
            for row in range(6):source[row][4]=rear[row]
        if actor in ['ivan','ivan_masked'] and (SOURCE/'ivan_rear.png').exists():
            rear=figures(SOURCE/'ivan_rear.png',2,6)[0 if actor=='ivan_masked' else 1]
            for row in range(6):source[row][4]=rear[row]
        clips=['ready','shot','reload','walk_left','walk_right','reload_walk_left','reload_walk_right']
        report[actor+'_combat']=pack(actor+'_combat',[source[i] for i in [0,0,3,1,2,4,5]],400,clips)
    (SOURCE/'packing_report.json').write_text(json.dumps(report,indent=2)+'\n')
    covers=SOURCE/'publication_covers.png'
    if covers.exists():
        books=[book for row in figures(covers,3,6) for book in row]
        extra=SOURCE/'publication_covers_extra.png'
        if extra.exists():books[16:18]=figures(extra,1,2)[0]
        for index,book in enumerate(books):
            book.thumbnail((152,200),Image.Resampling.LANCZOS)
            icon=Image.new('RGBA',(160,208));icon.alpha_composite(book,((160-book.width)//2,(208-book.height)//2))
            icon.save(ROOT/'assets/publications'/f'cover_{index:02d}.png',optimize=True)
    materials=SOURCE/'factory_materials.png'
    if materials.exists():
        sheet=Image.open(materials).convert('RGB')
        names=['factory_dry_v13','factory_damp_v13','factory_floor_tile_v13','factory_green_wall_v13','factory_plaster_v13','factory_wall_tile_v13','factory_enamel_v13','factory_oxide_v13']
        for i,name in enumerate(names):
            col,row=i%4,i//4
            bounds=(round(col*sheet.width/4)+3,round(row*sheet.height/2)+3,round((col+1)*sheet.width/4)-3,round((row+1)*sheet.height/2)-3)
            sheet.crop(bounds).resize((512,512),Image.Resampling.LANCZOS).save(ROOT/'assets/visual'/(name+'.png'),optimize=True)
    print('Packed',', '.join(report))

if __name__=='__main__':main()
