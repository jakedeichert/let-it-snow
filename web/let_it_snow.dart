import 'dart:html';
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart' show Vector2;

GameState gameState = GameState.PAUSED;
bool isTicking = false;
Random r = new Random();
String greeting = "";
String to = "";
String from = "";
String bg ="";
int numSnowflakes = 1000;
SnowfallParticleSystem snow;

// settings are grabbed from the url
// localhost.com/?to=you?from=me?snow=500?greeting=happy holidays?bg=image-url


void main() {
  init();
}

void init() {
  window.onResize.listen((event) => reset());
  querySelector("#menu-svg").onClick.listen((event) => toggleShowMenu());
  querySelector("#save").onClick.listen((event) => save());
  
  getSettings();
  activateSettings();
  updateMenu();
  
  startTick();
  play();
}

void save() {    
  // change the url
  var stringGreeting = (querySelector("#greetingText") as InputElement).value;
  var stringTo = (querySelector("#toText") as InputElement).value;
  var stringFrom = (querySelector("#fromText") as InputElement).value;
  var stringSnow = (querySelector("#snowAmountText") as InputElement).value;
  var stringBg = (querySelector("#backgroundText") as InputElement).value;
  

  var newSearchString = "";
  if (stringGreeting != "") newSearchString += "&greeting=" + stringGreeting;
  if (stringTo != "") newSearchString += "&to=" + stringTo;
  if (stringFrom != "") newSearchString += "&from=" + stringFrom;
  if (stringSnow != "" && stringSnow != "1000") newSearchString += "&snow=" + stringSnow;
  if (stringBg != "") newSearchString += "&bg=" + stringBg;
  
  // the pattern is usually ?firstparam=...&second=...&third...&etc
  newSearchString = newSearchString.replaceFirst("&", "?");
  
  window.location.search = newSearchString;
}

void toggleShowMenu() {
  querySelector("#menu-box").classes.toggle("show");
  querySelector("#menu-box").classes.toggle("hide");
  querySelector("#menu-svg").classes.toggle("active");
}

void updateMenu() {  
  var bgPublic = bg;
  if (bgPublic == "images/bg.png") bgPublic = "";
  (querySelector("#greetingText") as InputElement).value = greeting;
  (querySelector("#toText") as InputElement).value = to;
  (querySelector("#fromText") as InputElement).value = from;
  (querySelector("#snowAmountText") as InputElement).value = numSnowflakes.toString();
  (querySelector("#backgroundText") as InputElement).value = bgPublic;
}

void getSettings() {
  // get these values from the url
  greeting = getUriValue("greeting");
  to = getUriValue("to");
  from = getUriValue("from");
  bg = getUriValue("bg");
  if (bg == "") bg = "images/bg.png";
  
  String stringNumSnowflakes = getUriValue("snow");
  if (stringNumSnowflakes != "") {
    numSnowflakes = int.parse(stringNumSnowflakes);
  } else {
    numSnowflakes = 1000;
  }
}

void activateSettings() {
  querySelector("#to").innerHtml = to;
  querySelector("#greeting").innerHtml = greeting;
  querySelector("#from").innerHtml = from;
  document.body.style.backgroundImage = "url('" + bg + "')";
  snow = new SnowfallParticleSystem(numSnowflakes);
}

String getUriValue(String settingName) {
  var settings;
  var settingValue;
  
  if (window.location.search.indexOf(settingName) != -1) {
    settings = Uri.decodeFull(window.location.search.substring(window.location.search.indexOf(settingName)));
    if (settings.indexOf("?") != -1 || settings.indexOf("&") != -1 ) {
      settingValue = settings.substring(settings.indexOf("=") + 1, settings.indexOf("&"));
    } else {
      settingValue = settings.substring(settings.indexOf("=") + 1);
    }
    return settingValue;
  } else {
    return "";
  }
}

void reset() {
  Canvas.setSize(new Vector2((window.innerWidth).toDouble(), (window.innerHeight).toDouble()));
  updateMenu();
  
  snow.start();
}

void play() {
  reset();
  gameState = GameState.PLAYING;
}

void pause() {
  gameState = GameState.PAUSED;
}

void togglePause() {
  if (gameState == GameState.PAUSED) {
    play();
  } else if (gameState == GameState.PLAYING) {
    pause();
  }
}

void startTick() {
  if (!isTicking) {
    window.requestAnimationFrame(tick);
    isTicking = true;
  }
}

void stopTick() {
  isTicking = false;
}

void tick(num time) {
  if (isTicking) {
    switch (gameState) {
      
      case GameState.PLAYING:
        update(time);
        render();
        break;
        
      case GameState.PAUSED:
        break;
    }
    window.requestAnimationFrame(tick);
  }
}

void update(num time) {
  snow.update(time);
}

void render() {
  Canvas.clearRect();
  snow.render();
}


/********************************************************************************
  CLASSES
********************************************************************************/

class GameState {
  final _value;
  const GameState._internal(this._value);
  toString() => "Enum.$_value";

  static const PLAYING = const GameState._internal("PLAYING");
  static const PAUSED = const GameState._internal("PAUSED");
}

class State {
  final _value;
  const State._internal(this._value);
  toString() => "Enum.$_value";

  static const ACTIVE = const State._internal("PLAYING");
  static const INACTIVE = const State._internal("PAUSED");
}

class Color {
  static const String WHITE = "hsla(0, 0%, 100%, 1)";
  static const String BLACK = "hsla(0, 0%, 0%, 1)";
  String hsla = BLACK;
  
  Color(this.hsla);  
}

class Random {
  Math.Random r = new Math.Random();
  
  num range(num min, num max) {
    return (r.nextDouble() * (max + 1 - min) + min);
  }
}

class GameObject {
  Color color = new Color(Color.BLACK);
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;
  Vector2 size;
  Vector2 gravity;
  
  GameObject(this.position, this.velocity, this.acceleration, this.size, this.color); 
  
  void update(num time) {
    velocity += acceleration;
    position += velocity;
  }
}

class Rectangle extends GameObject {
  
  Rectangle(Vector2 position, Vector2 velocity, Vector2 acceleration, Vector2 size, Color color) :
    super(position, velocity, acceleration, size, color);
  
  void update(num time) {
    super.update(time);
  }
  
  void render() {
    Canvas.drawRect(position, size, color);
  }
}

class Snowflake extends Rectangle {
  num _amplitude;
  num _frequency;
  num _phase;
  num _phaseIncrement;
  
  Snowflake(Vector2 p, Vector2 v, Vector2 a, Vector2 s, Color c) : 
    super(p, v, a, s, c) {

    _amplitude = 1;
    _frequency = r.range(0.9, 1.5);
    _phase = r.range(-1, 1);
    _phaseIncrement = _frequency / 40;
    num s = r.range(0.8, 1.8);
    size = new Vector2(s, s);
  }
  
  void update(num time) {
    _phase += _phaseIncrement;
    
    position.y += velocity.y;
    position.x += Math.sin(_phase + _frequency);
    
    if (position.y + size.y > Canvas.size.y) position.y = -100.0;
  }
  
  void render() {
    super.render();
  }
  
}

class SnowfallParticleSystem {
  State _state = State.INACTIVE;
  final num _numParticles;
  List<Snowflake> _particles;
  
  SnowfallParticleSystem(this._numParticles);
  
  void update(num time) {
    if (_state == State.ACTIVE) {
      _particles.forEach((Snowflake p) => p.update(time));
    }
  }
  
  void render() {
    if (_state == State.ACTIVE) {
      _particles.forEach((Snowflake p) => p.render());
    }
  }
  
  void start() {
    _createParticles();
    _state = State.ACTIVE;
  }
  
  void _createParticles() {
    _particles = new List(_numParticles); 
    
    for (int i = 0; i < _particles.length; i++) {      
      _particles[i] = new Snowflake (
          new Vector2(r.range(-100, Canvas.size.x), r.range(-100, Canvas.size.y)),
          new Vector2(0.0, 0.8),
          new Vector2.zero(),
          new Vector2.zero(),
          new Color(Color.WHITE)
      );
    }
  }
  
}



class Canvas {
  static final CanvasElement _element = querySelector('#dart-canvas');
  static final CanvasRenderingContext2D _ctx = _element.getContext('2d');
  static Vector2 size = new Vector2.zero();
  

  static void clearRect([num x, num y, num width, num height]) {
    //var duration = milliseconds == null ? _TIMEOUT : _ms * milliseconds;
    // Uses default values if they aren't specified.
    x = x == null ? 0 : x;
    y = y == null ? 0 : y;
    width = width == null ? _element.width : width;
    height = height == null ? _element.height : height;
    
    _ctx.clearRect(x, y, width, height);
  }

  static void drawImage(ImageElement img, Vector2 srcPosition, Vector2 drawPosition, Vector2 srcSize) {
    _ctx.drawImageScaledFromSource(img, srcPosition.x, srcPosition.y,
       srcSize.x, srcSize.y,
       drawPosition.x, drawPosition.y,
       srcSize.x, srcSize.y);
  }
  
  static void _setFill(Color color) {
    _ctx.fillStyle = color.hsla;
  }

  static void drawRect(Vector2 p, Vector2 s, Color color) {
    _setFill(color);
    _ctx.fillRect(p.x, p.y, s.x, s.y);
  }

  static void setSize(Vector2 s) {
    _element.width = (s.x).toInt();
    _element.height = (s.y).toInt();
    size.x = s.x;
    size.y = s.y;
  }

  static void scale(Vector2 s) {
    _ctx.scale(s.x, s.y);
  }

  static void save() {
    _ctx.save();
  }

  static void restore() {
    _ctx.restore();
  }
}

