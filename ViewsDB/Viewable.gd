class_name Viewable
extends Resource

enum ViewableType {
    SCENE_2D,
    SCENE_3D,
    TEXTURE2D,
    VIDEOSTREAM
    } 

#var name : String
@export var name : String = ""
@export var type : ViewableType = ViewableType.TEXTURE2D
@export var resource : Resource = null
var thumbnail : Texture2D = null

func refreshThumbnail():
    match type:
        ViewableType.TEXTURE2D:
            thumbnail = resource
        ViewableType.SCENE_2D:
            pass
        ViewableType.SCENE_3D:
            pass
        ViewableType.VIDEOSTREAM:
            pass
        _:
            pass
            
