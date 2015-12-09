// general stuff
boolean debug = true;
int h = 300;
int w = 500;
String state = "game"; // menu, story, game, info

// data
ArrayList story;
ArrayList stages;
int story_index = 0;
int stage_index = 0;
boolean stage_finished = true;

Player player;
float base_speed = 3;
ArrayList entities = new ArrayList();
int entity_index = 0;
ArrayList bg_entities = new ArrayList();     // sparks, borders, speech bubbles, explosions
ArrayList collectables = new ArrayList();   // bullets, powerups
ArrayList actors = new ArrayList();         // player, enemies

boolean key_up = false;
boolean key_down = false;
boolean key_left = false;
boolean key_right = false;
boolean key_space = false;
boolean key_space_released = true;

/* Setting up canvas. */
void setup() {
    load_story();
    load_stages();

    smooth();
    size(w, h);
    frameRate(30);
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
        if (stage_finished) {
            populate_stage();
            stage_finished = false;
        }

        // main steps
        check_keys();
        update();
        draw_scene();
    }
}

/* Update positions, collisions, etc. */
void update() {
    // update positions
    for (int i = 0; i < entities.size(); i++) {
        // bg_entities, , collectables, actors
        ArrayList list = entities.get(i);
        for (int j = list.size()-1; j >= 0; j--) {
            Entity e = list.get(j);
            e.move(); // move every entity

            // TODO collision detection
            // TODO set stage_index++ if all enemies died

            // remove unused bullets & backgrounds
            if (e instanceof Bullet && (e.pos.x == w || e.pos.y == h)) {
                if (debug) println('Bullet ' + e.id + ' fell out of canvas.');
                list.remove(j);
                continue;
            }
            else if (e instanceof Border && e.pos.x < -50) {
                //if (debug) println('Border ' + e.id + ' fell out of canvas.');
                list.remove(j);
            }
        }
    }
}

void draw_scene() {
    // draw entities
    for (int i = 0; i < entities.size(); i++) {
        ArrayList list = entities.get(i);
        for (int j = 0; j < list.size(); j++) {
            Entity e = list.get(j);
            if (e instanceof Border) {
                if (e.pos.x <= w) { // only draw borders if visible
                    stroke(50);
                    fill(50);
                    beginShape();
                    int x = e.pos.x;
                    int y = e.pos.y;
                    vertex(x+e.pos1.x, y+e.pos1.y);
                    vertex(x+e.pos2.x, y+e.pos2.y);
                    vertex(x+e.pos3.x, y+e.pos3.y);
                    vertex(x+e.pos4.x, y+e.pos4.y);
                    endShape();
                    stroke(0);
                    fill(255);
                }
            } else {
                println("Drawing: " + e.id);
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
}

/* --------------- populate --------------- */

void populate_stage() {
    println("Until here...");
    if (stage_index == 0) populate_initial();

    String[] stage = stages.get(stage_index);
    println("Stage: " + stage);

    String[] type = split(stage[3], ',');
    String[] count = split(stage[4], ',');
    String[] health = split(stage[5], ',');
    String powerup = stage[6];

    // single enemies
    for (int i = 0; i < int(count[0]); i++) {
        PVector pos = new PVector(w + 30*(i-i%8)/8, 100 + i%8*15);
        PVector speed = new PVector(-0.5, 1);
        Enemy e = new Enemy(pos, speed, type[0], int(health[0]));
        println("Created enemy with id = " + e.id);
        actors.add(e);
    }
}

void populate_initial() {
    // build player
    PVector speed = new PVector(0, 0);
    PVector pos = new PVector(w/3, h/2);
    player = new Player(pos, speed);

    // build entity list
    entities.add(bg_entities);
    entities.add(collectables);
    entities.add(actors);
    actors.add(player);

    // sparks
    for (int i = 0; i < 40; i++) {
        PVector speed = new PVector(-1, 0);
        PVector pos = new PVector(int(random(w)), int(random(h)));
        String name ="spark" + str(int(random(3)));
        Spark s = new Spark(pos, speed, name);
        bg_entities.add(s);
    }

    // TODO repeat border generation if we run out of borders
    // upper border
    PVector pos = new PVector(0, 0);
    PVector speed = new PVector(-2, 0);
    PVector pos1 = new PVector(0, 0);
    PVector pos2 = new PVector(0, 30);
    for (int i = 0; i < 200; i++) {
        PVector pos3 = new PVector(20 + random(30), 20 + random(30));
        PVector pos4 = new PVector(pos3.x, 0);
        Border border = new Border(pos, speed, pos1, pos2, pos3, pos4);
        bg_entities.add(border);
        pos.x += pos4.x
        pos1 = new PVector(0, 0);
        pos2 = new PVector(0, pos3.y);
    }

    // lower border
    PVector pos = new PVector(0, h-50);
    PVector speed = new PVector(-2, 0);
    PVector pos1 = new PVector(0, h);
    PVector pos2 = new PVector(0, 30);
    for (int i = 0; i < 200; i++) {
        PVector pos3 = new PVector(20 + random(30), 50 - (20 + random(30)));
        PVector pos4 = new PVector(pos3.x, h);
        Border border = new Border(pos, speed, pos1, pos2, pos3, pos4);
        bg_entities.add(border);
        pos.x += pos4.x
        pos1 = new PVector(0, h);
        pos2 = new PVector(0, pos3.y);
    }
}

/* --------------- helper functions --------------- */

void load_story() {
    String[] lines = loadStrings("story.dat");
    story = new ArrayList();
    for (int i = 1; i < lines.length; i++) {
        String[] parts = split(lines[i], "|");
        story.add(parts);
    }
    if (debug) println('Loaded ' + story.size() + ' story entries.');
}

void load_stages() {
    String[] lines = loadStrings("stages.dat");
    stages = new ArrayList();
    for (int i = 1; i < lines.length; i++) {
        String[] parts = split(lines[i], "|");
        stages.add(parts);
    }
    if (debug) println('Loaded ' + stages.size() + ' stage entries.');
}

/* --------------- keyboard input --------------- */

/* Tracking which keys have been pressed. */
void keyPressed() {
    if (key == 'w') key_up = true;
    else if (key == 's') key_down = true;
    else if (key == 'a') key_left = true;
    else if (key == 'd') key_right = true;
    else if (key_space_released && (key == ' ' || keyCode == ENTER)) {key_space = true; key_space_released = false;}
}

void keyReleased() {
    if (key == 'w') key_up = false;
    else if (key == 's') key_down = false;
    else if (key == 'a') key_left = false;
    else if (key == 'd') key_right = false;
    else if (key == ' ' || keyCode == ENTER) {key_space = false; key_space_released = true;}
}

void check_keys() {
    /* directions */
    if (key_up) player.speed.y = -base_speed;
    else if (key_down) player.speed.y = base_speed;
    else player.speed.y = 0;

    if (key_left) player.speed.x = -base_speed;
    else if (key_right) player.speed.x = base_speed;
    else player.speed.x = 0;

    /* fire bullet */
    if (key_space) {
        player.fire_bullet();
        key_space = false;
    }
}


/* --------------- class definitions --------------- */

/* Main Entity */
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
        if (debug) println("Loaded image: " + name);
        img = loadImage("img/" + name + ".png");
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

/* Actor entities */
class Actor extends Entity {
    int health;

    Actor(PVector _pos, PVector _speed, String _type) {
        super(_pos, _speed);
        super.set_image(_type);
    }

    void fire_bullet(int direction, int damage) {
        println("Actor fires bullet with pos = " + pos);
        PVector speed = new PVector(direction*(base_speed + 1), 0);
        Bullet s = new Bullet(pos, speed, damage);
        collectables.add(s);
        println("Actor finished firing bullet!");
    }

    void get_hit(int damage) {
        health -= damage;
    }
}

class Player extends Actor {
    int bullet_damage = 10;
    int bullet_direction = 1;

    Player(PVector _pos, PVector _speed) {
        super(_pos, _speed, "player");
        health = 100;
    }

    void fire_bullet() {
        super.fire_bullet(bullet_direction, bullet_damage);
    }
}

class Enemy extends Actor {
    PVector buffer;

    Enemy(PVector _pos, PVector _speed, String _type, int _health) {
        super(_pos, _speed, _type);
        health = _health;
        buffer = new PVector(100, h/2);
    }

    void fire_bullet() {
        super.fire_bullet(-1);
    }

    void move() {
        // move into field if buffer > 0
        if (buffer.x > 0) {
            buffer.x += speed.x;
            pos.x += speed.x;
        }

        // y movement
        if (buffer.y > 180 || buffer.y < 120) {
            speed.y *= -1;
        }
        buffer.y += speed.y;
        pos.y += speed.y;

        // TODO fire shot at random
    }
}

/* Collectable entities */
class Collectable extends Entity {
    Collectable(PVector _pos, PVector _speed, String _type) {
        super(_pos, _speed);
        super.set_image(_type);
    }
}

class Bullet extends Collectable {
    int damage;

    Bullet(PVector _pos, PVector _speed, int _damage) {
        super(_pos, _speed, "bullet0");
        damage = _damage;
    }
}

class Powerup extends Collectable {
    String type; // guns, armor, health

    Powerup(PVector _pos, PVector _speed, String _type) {
        super(_pos, _speed, "powerup_" + _type);
        type = _type;
    }
}

/* Background entities */
class Spark extends Entity {
    Spark(PVector _pos, PVector _speed, String type) {
        super(_pos, _speed);
        super.set_image(type);
    }

    void move() {
        super.move();
        if (pos.x == 0) pos.x = w;
    }
}

class Border extends Entity {
    PVector pos1, pos2, pos3, pos4;

    Border(PVector _pos, PVector _speed, PVector _pos1, PVector _pos2, PVector _pos3, PVector _pos4) {
        super(_pos, _speed);
        pos1 = _pos1.get();
        pos2 = _pos2.get();
        pos3 = _pos3.get();
        pos4 = _pos4.get();
    }

    void move() {
        pos.x = pos.x + speed.x;
    }
}
