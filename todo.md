#TODO

##Transitions
[ ] add cleanup step in finish_transition function

just after assigning active_view, set the cleanup function depending on the viewable type (strategy pattern)
just before reassigning active_view, call the cleanup function
apply cleanup function before doing the viewport switcheroo
(clean up the "active" viewport, then switch. the inactive one should always be blank)

if we can have the scene render blank/holdout pixels, then we can simply use texture level transitions for everything, render one scene on top of the other, or do a pass using a depth texture or stencil texture


##Editor UI

add an action to force re-render of thumbnail for a viewable

implement loading in the viewable to the uv editor when clicking on a face in the display editor

