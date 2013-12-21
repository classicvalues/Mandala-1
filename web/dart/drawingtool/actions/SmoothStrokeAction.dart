part of DrawingToolLib;

class SmoothStrokeAction extends RegularStrokeAction {
  static const String ACTION_NAME = "SmoothStroke";

  Geom.Point _draggedPoint;

  SmoothStrokeAction() : super() {
    this.name = ACTION_NAME;
  }

  void execute(CanvasRenderingContext2D ctx, width, height) {
    settings.execute(ctx);
    executeImp( ctx, ctx.stroke, width, height );
  }


  void executeImp(CanvasRenderingContext2D ctx, Function drawCall, width, height) {
    // If the active points are not empty - set points to draw to the union of points & activePoints
    List<Geom.Point> pointsToDraw = null;
    if( _activePoints != null ) {
      pointsToDraw = new List<Geom.Point>.from(points);
      pointsToDraw.add(BaseAction.LINE_BREAK);
      pointsToDraw.addAll( _activePoints );
    } else {
      pointsToDraw = points;
    }

    /// We need at least 2 points
    if( pointsToDraw.isEmpty || pointsToDraw.length < 2 ) return;

    for(var i = 0; i < pointsToDraw.length - 1; i++) {

      // Null slot implies a new path should be started
      if( pointsToDraw[i] == BaseAction.LINE_BREAK ) {

        // Close existing path
        if( i != 0 ) {
          drawCall();
          ctx.closePath();
        }

        ctx.beginPath();
        ctx.moveTo( pointsToDraw[i+1].x, pointsToDraw[i+1].y );
        continue;
      }

      Geom.Point cp = pointsToDraw[i+1];

      // If it's a linebreak, then that means the current point was the last point on this curve
      if( cp == BaseAction.LINE_BREAK ) {
        continue;
      }

      // Use the current point as a control point, and set the curve to stop halfway to the next point
      // It's kind of weird that this works as well as it does, but i figured it out when creating http://ribbonpaint.com - so im using it again
      ctx.quadraticCurveTo(pointsToDraw[i].x, pointsToDraw[i].y,
      (pointsToDraw[i].x+cp.x) * 0.5, (pointsToDraw[i].y+cp.y)*0.5);
    }
    drawCall();
    ctx.closePath();
  }

  void activeDraw(CanvasRenderingContext2D ctx, width, height, bool shouldDrawEditablePoints) {
    if( !shouldDrawEditablePoints ) return;

    for(var i = 0; i < points.length; i++) {
      if( points[i] == BaseAction.LINE_BREAK ) continue;
      ctx.beginPath();
      ctx.arc(points[i].x, points[i].y, BaseAction.MIN_DRAG_DISTANCE, 0, PI * 2, false);
      ctx.stroke();
      ctx.closePath();
    }
  }

  void inputDown(CanvasRenderingContext2D ctx, Geom.Point pos, bool canEditPoints) {
    if( canEditPoints ) {
      for(var i = 0; i < points.length; i++) {
        if( points[i] == BaseAction.LINE_BREAK ) continue;
        if( points[i].distanceTo( pos ) <= BaseAction.MIN_DRAG_DISTANCE ) {
          _draggedPoint = points[i];
          return;
        }
      }
    }
    super.inputDown( ctx, pos, canEditPoints );
  }

  void inputMove(CanvasRenderingContext2D ctx, Geom.Point pos, bool isDrag) {
    // Drag the control point instead
    if( _draggedPoint != null ) {
      _draggedPoint.copyFrom( pos );
      return;
    }

    super.inputMove( ctx, pos, isDrag );
  }

  void inputUp(CanvasRenderingContext2D ctx, Geom.Point pos) {
    // User was dragging - abort!
    if( _draggedPoint != null ) {
      _draggedPoint = null;
      return;
    }

    int oldLen = _activePoints.length;
    var simplifiedSmoothedPoints =  LineGeneralization.simplifyLang(10, 3, _activePoints) ;//LineGeneralization.smoothMcMaster( LineGeneralization.smoothMcMaster( LineGeneralization.simplifyLang(4, 1, _activePoints) ) );

    print("Removed previously had ${oldLen}, now have ${simplifiedSmoothedPoints.length}, Removed ${oldLen - simplifiedSmoothedPoints.length} points");
    
    points.add(BaseAction.LINE_BREAK);
    points.addAll(simplifiedSmoothedPoints);

    _activePoints = null;
  }
}