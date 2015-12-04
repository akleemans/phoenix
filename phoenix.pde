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
int entity_index = 0;

boolean key_up = false;
boolean key_down = false;
boolean key_left = false;
boolean key_right = false;
boolean key_space = false;

/* Setting up canvas. */
void setup() {
    load_story();
    //load_levels();
    //load_images();

    PVector speed = new PVector(0, 0);
    PVector pos = new PVector(w/3, h/2);
    player = new Player(pos, speed);
    entities.add(player);

    smooth();
    size(w, h);
    frameRate(30);
}

/* Tracking which keys have been pressed. */
void keyPressed() {
    if (key == CODED) {
        if (keyCode == UP) key_up = true;
        if (keyCode == DOWN) key_down = true;
        if (keyCode == LEFT) key_left = true;
        if (keyCode == RIGHT) key_right = true;
    }
    // only allow shooting if some time passed
    else if (keyCode == ' ') {
        key_space = true;
    }
}

void keyReleased() {
    if (key == CODED) {
        if (keyCode == UP) key_up = false;
        if (keyCode == DOWN) key_down = false;
        if (keyCode == LEFT) key_left = false;
        if (keyCode == RIGHT) key_right = false;
    }
}

void check_keys() {
    /* directions */
    if (key_up) player.speed.y = -base_speed;
    else if (key_down) player.speed.y = base_speed;
    else player.speed.y = 0;

    if (key_left) player.speed.x = -base_speed;
    else if (key_right) player.speed.x = base_speed;
    else player.speed.x = 0;

    /* fire shot */
    if (key_space) player.fire_shot();
}

/* Update positions, collisions, etc. */
void update() {
    // update positions
    for (int i = entities.size()-1; i >= 0; i--) {
        Entity e = entities.get(i);
        e.move(); // move every entity

        // TODO collision detection

        // remove unused bullets
        if (e instanceof Shot && (e.pos.x == w || e.pos.y == h)) {
            if (debug) println('Shot ' + e.id + ' fell out of canvas.');
            entities.remove(i);
            continue;
        }
    }
}

/* Main loop */
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
            Entity e = entities.get(i);
            x = e.pos.x;
            y = e.pos.y;

            pushMatrix();
            translate(x, y);
            ////rotate(b.rot);
            image(e.img, -e.img.width/2, -e.img.height/2);
            popMatrix();
        }
    }
}

/* Helper functions */
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
class Entity {
    int id;
    PImage img;
    PVector pos;
    PVector speed;

    Entity(PVector _pos, PVector _speed) {
        id = entity_index++;
        pos = _pos.get(); // copy
        speed = _speed.get(); // copy
    }

    void set_image(String name) {
        img = loadImage("img/" +name + ".png");
    }

    /* Moving */
    void move() {
        pos.x = pos.x + speed.x;
        pos.y = pos.y + speed.y;

        if (pos.x < 0) pos.x = 0;
        else if (pos.x > w) pos.x = w;

        if (pos.y < 0) pos.y = 0;
        else if (pos.y > h) pos.y = h;
    }
}

class Player extends Entity {
    Player(PVector _pos, PVector _speed) {
        super(_pos, _speed);
        super.set_image("player");
    }
    void fire_shot() {
        // TODO check when last shot was fired
        PVector speed = new PVector(base_speed + 1, 0);
        Shot s = new Shot(pos, speed);
        if (debug) println('Firing shot ' + s.id + '...');
        entities.add(s);
        key_space = false;
    }
}

class Shot extends Entity {
    Shot(PVector _pos, PVector _speed) {
        super(_pos, _speed);
        super.set_image("bullet0");
    }
}
