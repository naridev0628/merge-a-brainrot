"""Author recessed ground, board surfaces and a block tree in Blender.

blender --background --python tools/build_ground_review.py
Exports real single-mesh assets with one embedded palette and editable .blend.
"""
import bpy, math, json, struct, zlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/map/ground_review'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
# Explicit sRGB PNG bytes avoid generated-image colour-space ambiguity.
# Narrower greens retain the molded detail without a fluorescent, dark-lined grid.
PALETTES={
 'Green':((84,132,67),(112,171,81),(139,197,103)),
 'Gold':((142,111,66),(202,166,108),(237,208,155)),
 'Brown':((94,66,47),(151,110,78),(191,151,111)),
 'Edge':((49,85,43),(71,116,59),(100,149,77)),
 'Bark':((65,46,34),(116,83,56),(162,123,83)),
 'Leaf':((48,91,43),(87,140,62),(133,179,89)),
}
palette=[];lookup={}
for name,stops in PALETTES.items():
 for shade in range(16):
  t=shade/15*2;lo=min(1,int(t));fraction=t-lo
  color=tuple(round(stops[lo][i]*(1-fraction)+stops[lo+1][i]*fraction) for i in range(3))
  lookup[name,shade]=len(palette);palette.append(color)
while len(palette)<128:palette.append(palette[95])
def png_chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
rows=[]
for y in range(64):
 row=7-y//8;pixels=bytearray()
 for x in range(128):
  level=max(0,min(15,(x+.5)/8-.5));lo=int(level);hi=min(15,lo+1);t=level-lo
  pixels.extend(round(palette[row*16+lo][i]*(1-t)+palette[row*16+hi][i]*t) for i in range(3))
 rows.append(b'\x00'+pixels)
png=b'\x89PNG\r\n\x1a\n'+png_chunk(b'IHDR',struct.pack('>IIBBBBB',128,64,8,2,0,0,0))+png_chunk(b'sRGB',b'\x00')+png_chunk(b'IDAT',zlib.compress(b''.join(rows),9))+png_chunk(b'IEND',b'')
(OUT/'GroundReviewPalette.png').write_bytes(png)
img=bpy.data.images.load(str(OUT/'GroundReviewPalette.png'));img.name='GroundReviewPalette';img.pack()
material=bpy.data.materials.new('GroundReview_Atlas');material.use_nodes=True
shader=material.node_tree.nodes.get('Principled BSDF')
shader.inputs['Roughness'].default_value=.82
texture=material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image=img;texture.interpolation='Linear'
material.node_tree.links.new(texture.outputs['Color'],shader.inputs['Base Color'])

class Builder:
    def __init__(self):self.vertices=[];self.faces=[];self.colors=[];self.expected=[]
    def face(self,points,color,normal):
        offset=len(self.vertices);self.vertices.extend(points)
        self.faces.append(tuple(range(offset,offset+len(points))));self.colors.append(color);self.expected.append(Vector(normal))
    def finish(self,name):
        mesh=bpy.data.meshes.new(name+'Geometry')
        mesh.from_pydata(self.vertices,[],self.faces);mesh.update()
        obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
        mesh.materials.append(material);uv=mesh.uv_layers.new(name='UVMap')
        for face,color in zip(mesh.polygons,self.colors):
            colors=color if isinstance(color,list) else [color]*len(face.loop_indices)
            for loop,value in zip(face.loop_indices,colors):
                uv.data[loop].uv=((value%16+.5)/16,(math.floor(value/16)+.5)/8)
        mesh.calc_loop_triangles()
        assert all(t.area>1e-10 for t in mesh.loop_triangles),name+' has a degenerate face'
        assert all(face.normal.dot(expected)>.01 for face,expected in zip(mesh.polygons,self.expected)),name+' has reversed relief normals'
        assert all(t.normal.dot(mesh.polygons[t.polygon_index].normal)>.999 for t in mesh.loop_triangles),name+' has reversed triangulation'
        obj['NormalAuditMinDot']=min(face.normal.dot(expected) for face,expected in zip(mesh.polygons,self.expected))
        return obj

def clip_polygon(points,limit):
    """Clip the triangle variant to x+y <= limit, preserving planar UV faces."""
    result=[]
    for i,a in enumerate(points):
        b=points[(i+1)%len(points)]
        da=a[0]+a[1]-limit;db=b[0]+b[1]-limit
        if da<=1e-8:result.append(a)
        if (da< -1e-8 and db>1e-8) or (da>1e-8 and db< -1e-8):
            t=da/(da-db);result.append(tuple(a[j]+(b[j]-a[j])*t for j in range(3)))
    # Deduplicate an exactly clipped corner.
    clean=[]
    for p in result:
        if not clean or (Vector(p)-Vector(clean[-1])).length>1e-8:clean.append(p)
    if len(clean)>1 and (Vector(clean[0])-Vector(clean[-1])).length<1e-8:clean.pop()
    return clean

def surface(builder,width,height,nx,ny,palette_name,origin=(0,0,0),u=(1,0,0),v=(0,1,0),
            depth=.16,top=.18,square=False,triangle=False):
    origin,u,v=Vector(origin),Vector(u),Vector(v);normal=u.cross(v)
    def field(x,y):
        # Continuous multi-frequency hue field: vertices shared by neighbouring
        # cells sample the same colour; periodic endpoints avoid tile seams.
        value=10.8+1.65*math.sin(x/width*math.tau)+1.0*math.cos(y/height*math.tau)+.65*math.sin((x/width+y/height)*math.tau)
        if palette_name=='Edge':value=10.0+2.0*y/height+1.1*math.sin(x/width*math.tau)
        return max(6.5,min(14.5,value))
    def emit(points,offset=0,constant=None):
        if triangle:points=clip_polygon(points,0)
        if len(points)<3:return
        out=[tuple(origin+u*x+v*y+normal*z) for x,y,z in points]
        if sum((Vector(out[i])-Vector(out[0])).cross(Vector(out[i+1])-Vector(out[0])).length for i in range(1,len(out)-1))<1e-9:return
        shades=[max(.2,min(15,constant if constant is not None else field(x,y)+offset)) for x,y,z in points]
        builder.face(out,[lookup[palette_name,0]+value for value in shades],normal)
    def corners(cx,cy,hx,hy,z):
        return [(cx-hx,cy-hy,z),(cx+hx,cy-hy,z),(cx+hx,cy+hy,z),(cx-hx,cy+hy,z)]
    for ix in range(nx):
        for iy in range(ny):
            cx=(ix+.5)*width/nx-width/2;cy=(iy+.5)*height/ny-height/2
            hx=width/nx/2;hy=height/ny/2
            if triangle and cx+cy-hx-hy>=-1e-8:continue
            # Four matched square loops, not alternating chamfer/corner vertices.
            # A complete contrasting frame survives filtering at gameplay distance.
            outer=corners(cx,cy,hx,hy,top-depth*.075)
            lip=corners(cx,cy,hx*.63,hy*.63,top)
            mouth=corners(cx,cy,hx*.51,hy*.51,top-depth*.22)
            floor=corners(cx,cy,hx*.46,hy*.46,top-depth)
            for i in range(4):
                j=(i+1)%4
                emit([outer[i],outer[j],lip[j],lip[i]])
                emit([lip[i],lip[j],mouth[j],mouth[i]],offset=-3.0)
                # Both far AND near edges are shaded. A bright floor cannot erase
                # half the recess and leave the previous dark chevron silhouette.
                emit([mouth[i],mouth[j],floor[j],floor[i]],offset=-5.0 if i in (0,3) else -3.6)
            emit(floor,offset=-2.4)

models=[]
for name in ('Green','Gold','Brown'):
    for triangle in (False,True):
        b=Builder();surface(b,16,16,8,8,name,triangle=triangle)
        models.append(b.finish('Ground'+name+('Triangle' if triangle else 'Tile')))
b=Builder();surface(b,16,8,8,4,'Edge')
models.append(b.finish('GroundGreenEdge'))

# A single authored tree with dark inset trunk, real branches and an asymmetric
# block canopy. Reuse the current BrickTree envelope to avoid new obstructions.
tree=Builder()
def tree_box(center,size,color,pitch=1.45):
    c=Vector(center);sx,sy,sz=size
    for origin,u,v,w,h in [
        (c+Vector((0,0,sz/2)),(1,0,0),(0,1,0),sx,sy),
        (c-Vector((0,0,sz/2)),(-1,0,0),(0,1,0),sx,sy),
        (c-Vector((0,sy/2,0)),(1,0,0),(0,0,1),sx,sz),
        (c+Vector((0,sy/2,0)),(-1,0,0),(0,0,1),sx,sz),
        (c+Vector((sx/2,0,0)),(0,1,0),(0,0,1),sy,sz),
        (c-Vector((sx/2,0,0)),(0,-1,0),(0,0,1),sy,sz),
    ]:
        surface(tree,w,h,max(1,math.ceil(w/pitch)),max(1,math.ceil(h/pitch)),color,
                origin=origin,u=u,v=v,depth=.055,top=0,square=True)
tree_box((-.15,.1,3.8),(1.65,1.55,7.6),'Bark',1.35)
tree_box((-1.25,.05,5.1),(2.45,1.1,1.1),'Bark',1.35)
tree_box((1.05,.15,6.4),(2.15,1.15,1.2),'Bark',1.35)
tree_box((-.40,.05,8.0),(3.65,3.45,3.8),'Leaf')
tree_box((-1.85,.3,7.0),(2.8,2.75,2.3),'Leaf')
tree_box((1.65,.35,8.55),(3.1,3.05,2.6),'Leaf')
tree_box((-.05,.65,10.75),(3.1,2.7,2.6),'Leaf')
tree_box((.65,-1.3,9.5),(2.8,2.0,1.6),'Leaf')
tree_obj=tree.finish('ReviewBrickTree')
lo=[min(v.co[i] for v in tree_obj.data.vertices) for i in range(3)]
hi=[max(v.co[i] for v in tree_obj.data.vertices) for i in range(3)]
target=(6.4535007477,5.3535003662,12.0535001755)
for vertex in tree_obj.data.vertices:
    vertex.co=Vector(((vertex.co.x-(lo[0]+hi[0])/2)*target[0]/(hi[0]-lo[0]),
                      (vertex.co.y-(lo[1]+hi[1])/2)*target[1]/(hi[1]-lo[1]),
                      (vertex.co.z-lo[2])*target[2]/(hi[2]-lo[2])))
tree_obj.data.update();tree_obj.data.calc_loop_triangles()
assert len(tree_obj.data.loop_triangles)<10000
models.append(tree_obj)

stats={}
for index,obj in enumerate(models):
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.export_scene.gltf(filepath=str(OUT/(obj.name+'.glb')),export_format='GLB',use_selection=True,export_apply=True)
    verts=[v.co for v in obj.data.vertices]
    minimum=[min(v[i] for v in verts) for i in range(3)]
    maximum=[max(v[i] for v in verts) for i in range(3)]
    stats[obj.name]={'triangles':len(obj.data.loop_triangles),'vertices':len(verts),
                     'robloxSize':[maximum[i]-minimum[i] for i in (0,2,1)],
                     'robloxCenter':[(maximum[i]+minimum[i])/2 for i in (0,2,1)],
                     'normalAuditMinDot':obj['NormalAuditMinDot']}
    assert stats[obj.name]['triangles']<10000
    obj.location=(index%4*20,index//4*20,0)

bpy.ops.object.select_all(action='DESELECT')
for obj in models:obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'GroundDetailImport.glb'),export_format='GLB',use_selection=True,export_apply=True)
raw=(OUT/'GroundDetailImport.glb').read_bytes();length=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+length])
assert len(doc['meshes'])==len(models)
assert all('bufferView' in image for image in doc.get('images',[]))
(OUT/'mesh-stats.json').write_text(json.dumps(stats,indent=2))

# Render a direct surface/edge comparison and a tree portrait.
for obj in models:obj.hide_render=True
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast'
scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.62,.68,.76,1)
scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
scene.render.image_settings.file_format='PNG'
bpy.ops.object.light_add(type='SUN',location=(0,0,20))
bpy.context.object.data.energy=1.1;bpy.context.object.rotation_euler=(.35,-.45,-.5)
bpy.ops.object.camera_add(location=(22,-30,34));camera=bpy.context.object
camera.data.type='ORTHO';camera.data.ortho_scale=38;scene.camera=camera
def point_camera(target):camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
point_camera((0,0,0))
for location,power,size in [((-14,-10,26),1100,15),((15,5,20),750,12)]:
    bpy.ops.object.light_add(type='AREA',location=location)
    lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=size
    lamp.rotation_euler=(-lamp.location).to_track_quat('-Z','Y').to_euler()
for name,x in [('GroundGreenTile',-9),('GroundGoldTile',9)]:
    obj=bpy.data.objects[name];obj.hide_render=False;obj.location=(x,0,0)
edge=bpy.data.objects['GroundGreenEdge'];edge.hide_render=False;edge.location=(-9,-8,-4)
edge.rotation_euler=(math.pi/2,0,0)
scene.render.filepath=str(OUT/'GroundSurfacePreview.png');bpy.ops.render.render(write_still=True)
# Gameplay-distance proof: repeated patches and an avatar-height scale figure.
for obj in models:obj.hide_render=True
stage=[]
source=bpy.data.objects['GroundGreenTile']
for x in range(4):
 for y in range(4):
  tile=source.copy();tile.data=source.data;tile.hide_render=False
  tile.location=((x-1.5)*16,(y-1.5)*16,0);bpy.context.collection.objects.link(tile);stage.append(tile)
for name,pos,size,color in [
 ('Scale left leg',(-.70,-8,1.65),(1.10,1.18,3.3),(.055,.10,.15)),
 ('Scale right leg',(.70,-8,1.65),(1.10,1.18,3.3),(.055,.10,.15)),
 ('Scale torso',(0,-8,4.65),(2.75,1.30,2.70),(.10,.38,.68)),
 ('Scale left arm',(-1.95,-8,4.65),(1.05,1.15,2.70),(.85,.65,.45)),
 ('Scale right arm',(1.95,-8,4.65),(1.05,1.15,2.70),(.85,.65,.45)),
 ('Scale head',(0,-8,6.85),(1.65,1.55,1.70),(.85,.65,.45)),
]:
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);obj=bpy.context.object;obj.name=name;obj.dimensions=size
 mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);obj.data.materials.append(mat);stage.append(obj)
camera.location=(55,-82,89);camera.data.ortho_scale=105;point_camera((0,0,0))
scene.render.filepath=str(OUT/'GroundGameplayPreview.png');bpy.ops.render.render(write_still=True)
for obj in stage:obj.hide_render=True
for obj in models:obj.hide_render=True
tree_obj.hide_render=False;tree_obj.location=(0,0,0)
camera.location=(16,-25,17);camera.data.ortho_scale=16;point_camera((0,0,6))
scene.render.resolution_x=900;scene.render.resolution_y=1000
scene.render.filepath=str(OUT/'TreePreview.png');bpy.ops.render.render(write_still=True)
for index,obj in enumerate(models):
    obj.hide_render=False;obj.location=(index%4*20,index//4*20,0);obj.rotation_euler=(0,0,0)
camera.location=(42,-50,58);camera.data.ortho_scale=83;point_camera((29,10,0))
scene.render.resolution_x=1280;scene.render.resolution_y=720
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GroundReview.blend'))
print('GROUND_REVIEW_READY',json.dumps(stats),flush=True)
