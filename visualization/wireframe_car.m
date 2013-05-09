function wireframe = wireframe_car()
edges = {
    'R HeadLight','L HeadLight';
    'R TailLight','L TailLight';
    
    'R HeadLight','R F WheelCenter';
    'L HeadLight','L F WheelCenter';
    
    'R TailLight','R B WheelCenter';
    'L TailLight','L B WheelCenter';
    
    'R B WheelCenter','L B WheelCenter';
    'R F WheelCenter','L F WheelCenter';
    
    'R B WheelCenter','R F WheelCenter';
    'L B WheelCenter','L F WheelCenter';
    
    'L F RoofTop','L B RoofTop';
    'L F RoofTop','R F RoofTop';
    'R B RoofTop','L B RoofTop';
    'R B RoofTop','R F RoofTop';
    
    'L F RoofTop','L SideviewMirror';
    'R F RoofTop','R SideviewMirror';
    
    'R SideviewMirror','L SideviewMirror';
    
    'L B RoofTop','L TailLight';
    'R B RoofTop','R TailLight';
    
    'L HeadLight','L SideviewMirror';
    'R HeadLight','R SideviewMirror';
 };


wireframe.edges = edges;