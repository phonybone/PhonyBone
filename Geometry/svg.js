var interval=40;
var h=0;
function svg_init(evt) {
  timer=setInterval('timer_callback()', interval);
  parent.document.timer=timer;
}

function timer_callback(evt) {
  move_elements(h++);
  if (h>=max_h) h=0;
}

function move_elements(h) {
  var data=timedata[h];
  for (var i=0; i<data.points.length; i++) {
    var pt=data.points[i];
    var elem=document.getElementById('point_'+i);
    elem.setAttribute('cx',pt.x);
    elem.setAttribute('cy',pt.y);
  }

  var linedata=data.lines;
  for (ln in linedata) {
    var ln_id=ln.substr(2);
    var elem=document.getElementById(ln_id);
    elem.setAttribute('x1',data.lines[ln].x1);
    elem.setAttribute('y1',data.lines[ln].y1);
    elem.setAttribute('x2',data.lines[ln].x2);
    elem.setAttribute('y2',data.lines[ln].y2);
  }
}