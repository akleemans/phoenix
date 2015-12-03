// general stuff
boolean debug = true;
int h = 400;
int w = 600;
String state = "story"; // menu, story, game, info

// data
ArrayList story;
ArrayList levels;
int story_index = 0;
int level_index = 0;

Player player;
float base_speed = 3;
ArrayList entities = new ArrayList();

HashMap keys = new HashMap();

/* Setting up canvas and populating boids. */
void setup() {
    load_story();
    //load_levels();
    //load_images();
    prepare_keys();

    PVector speed = new PVector(0, 0);
    PVector pos = new PVector(w/3, h/2);
    player = new Player(0, pos, speed);
    entities.add(player);

    smooth();
    size(w, h);
    frameRate(30);
}

/* Tracking which keys have been pressed. */
void prepare_keys() {
    keys.put("up", false);
    keys.put("down", false);
    keys.put("left", false);
    keys.put("right", false);
}

void keyPressed() {
    if (key == CODED) {
        if (keyCode == UP) keys.put("up", true);
        if (keyCode == DOWN) keys.put("down", true);
        if (keyCode == LEFT) keys.put("left", true);
        if (keyCode == RIGHT) keys.put("right", true);
    }
}

void keyReleased() {
    if (key == CODED) {
        if (keyCode == UP) keys.put("up", false);
        if (keyCode == DOWN) keys.put("down", false);
        if (keyCode == LEFT) keys.put("left", false);
        if (keyCode == RIGHT) keys.put("right", false);
    }
}

void check_keys() {
    /* UP and DOWN */
    if (keys.get("up")) player.speed.y = -base_speed;
    else if (keys.get("down")) player.speed.y = base_speed;
    else player.speed.y = 0;
    /* LEFT and RIGHT */
    if (keys.get("left")) player.speed.x = -base_speed;
    else if (keys.get("right")) player.speed.x = base_speed;
    else player.speed.x = 0;
}

/* Update positions, collisions, etc. */
void update() {
    // update positions
    player.move();
    // for entity in entities...
}

/* Main loop. */
void draw() {
    /* drawing */
    background(255);
    stroke(0, 0, 0);
    rect(0, 0, w-1, h-1);

    if (state.equals("menu")) {
        // menu
    } else if (state.equals("story")) {
        println(story.get(story_index)[2]);
        story_index += 1;
        if (story_index == story.size()-1) state = "game";
    } else if (state.equals("game")) {
        check_keys();
        update();

        // draw entities
        for (int i = 0; i < entities.size(); i++) {
            Player e = entities.get(i);
            x = e.pos.x;
            y = e.pos.y;

            pushMatrix();
            translate(x, y);
            ////rotate(b.rot);
            image(e.img, -e.img.width/2, -e.img.height/2);
            popMatrix();
        }
        // game
    }
}

/* Helper functions. */
void load_story() {
    String[] lines = loadStrings("story.dat");
    story = new ArrayList();
    for (int i = 1; i < lines.length; i++) {
        String[] parts = split(lines[i], "|");
        story.add(parts);
    }
    if (debug) println('Loaded ' + story.size() + ' story entries.');
}


/* Classes */
class Player {
    int id;
    PImage img;
    PVector pos;
    PVector speed;

    Player(int _id, PVector _pos, PVector _speed) {
        id = _id;
        img = loadImage("img/player.png");
        pos = _pos.get(); // copy
        speed = _speed.get(); // copy
    }

    /* Moving */
    void move() {
        pos.x = pos.x + speed.x;
        pos.y = pos.y + speed.y;

        // TODO check if out of bounds
    }
}
