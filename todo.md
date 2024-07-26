#TODO

implement thumbnailer process for viewables of:
[x] SCENE_3D
[ ] SCENE_2D
[ ] VIDEOSTREAM

instead of manually creating a viewsDB resource, designate a folder to traverse for .tres files and populate the viewDB that way at runtime/compiletime

also create views referencing the above

implement loading in the viewable to the uv editor when clicking on a face in the display editor


===

- create an editor server that both the display world angel and the UV editor angel connect to and can pass data back and forth
    - face selected, current UVs, current view/viewable
    - uvs updated
    - viewable updated
    - new view created
    - different view selected

Editor server/god lives as node child of main window. however it is spawned as the instance of a singleton class.
This way anyone who needs to can retrieve a reference to it at any time
