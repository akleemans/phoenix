// general stuff
boolean debug = false;
int h = 300;
int w = 500;
String state = "menu"; // menu, story, game, finished

// data to be loaded
ArrayList story;
boolean menu_initialized = false;
int story_index = 0;
int story_timestamp = 0;
int stage_index = 0;
int max_stage_index = 13;
boolean stage_finished = true;
boolean won = false;
int stage_timestamp = 0;
HashMap images;
PFont font;

Player player;
float base_speed = 3;
int entity_index = 0;
ArrayList bg_entities = new ArrayList();    // sparks, borders, speech bubbles, explosions
ArrayList passives = new ArrayList();       // speech bubbles, text
ArrayList collectables = new ArrayList();   // bullets, powerups
ArrayList enemies = new ArrayList();        // enemies

boolean key_up = false;
boolean key_down = false;
boolean key_left = false;
boolean key_right = false;
boolean key_space = false;
boolean key_space_released = true;

/* Setting up canvas. */
void setup() {
    load_story();
    load_images();
    font = loadFont("Verdana.ttf");
    textFont(font);

    smooth();
    size(w, h);
    frameRate(30);
}

/* Main loop */
void draw() {
    background(255);
    stroke(0, 0, 0);
    rect(0, 0, w-1, h-1);

    if (state.equals("menu")) {
        draw_text("Press space to start", new PVector(310, 220), 300, 100, 20);
        if (!menu_initialized) {
            PVector speed = new PVector(0, 0);
            PVector pos = new PVector(250, 100);
            Spark s = new Spark(pos, speed, "logo");
            bg_entities.add(s);
            menu_initialized = true;
        }
        check_menu_keys();
        draw_scene();
    } else if (state.equals("story")) {
        // new part of story
        if (story_timestamp == 0 || story_timestamp == frameCount) {
            if (story_index == story.size()) { // finished with story?
                state = "game";
                passives.clear();
            } else {
                if (story_timestamp == 0) {
                    bg_entities.clear();
                    populate_initial();
                }
                add_bubble(story.get(story_index)[1], story.get(story_index)[2]);
                story_timestamp = frameCount + 30 * int(story.get(story_index)[0]);
                story_index += 1;
            }
        }
        update();
        draw_scene();
        if (debug && skip_story()) {
            story_timestamp = 0;
            story_index = story.size()
        }
    } else if (state.equals("game")) {
        if (stage_finished && stage_index == max_stage_index) {
            if (debug) println("Max stage reached, finish");
            state = "finished";
            won = true;
        }
        if (stage_finished && stage_timestamp <= frameCount) {
            populate_stage();
            stage_finished = false;
            stage_index += 1;
            if (debug) println("draw(), stage_index = " + stage_index + " - max_stage_index = " + max_stage_index);
        }

        // main steps
        check_keys();
        update();
        draw_scene();
    } else if (state.equals("finished")) {
        if (won) {
            draw_text("VICTORY!", new PVector(300, 160), 300, 100, 50);
            draw_text("Thanks for playing! :)", new PVector(320, 220), 300, 100, 20);
        } else {
            draw_text("DEFEAT", new PVector(310, 170), 300, 100, 50);
        }
        draw_scene();
    }
}

/* Update positions, collisions, etc. */
void update() {
    // check if game finished
    if (player.health <= 0) {
        state = "finished";
    }

    // check if stage finished
    if (!stage_finished && state.equals("game") && enemies.size() == 0) {
        if (debug) println("Finished stage.");
        stage_finished = true;
        stage_timestamp = frameCount + 5*30;
    }

    // background: sparks, borders
    for (int i = bg_entities.size()-1; i >= 0; i--) {
        Entity e = bg_entities.get(i);
        e.move();
        if (e.pos.x < -50) bg_entities.remove(i);
        else if (e instanceof Explosion && e.type == 4) bg_entities.remove(i);
    }

    // collectables: bullets, powerups
    for (int i = 0; i < collectables.size(); i++) {
        Collectable c = collectables.get(i);
        c.move();
        if (c.pos.x > w+20 || c.pos.y > h+20 || c.pos.x < -20 || c.pos.y < -20) {
            collectables.remove(i);
        }
    }

    // enemies
    for (int i = enemies.size()-1; i >= 0; i--) {
        Enemy e = enemies.get(i);
        e.move();
        for (int j = collectables.size()-1; j >= 0; j--) {
            Collectable c = collectables.get(j);
            if (c instanceof PlayerBullet && check_collision(e, c)) {
                e.get_hit(c.damage);
                collectables.remove(j);
            }
            if (e.health <= 0) {
                Explosion ex = new Explosion(e.pos);
                bg_entities.add(ex);
                if (e instanceof Boss && !e.powerup.equals("")) {
                    Powerup p = new Powerup(e.pos, e.powerup);
                    collectables.add(p);
                }

                enemies.remove(i);
                break;
            }
        }
    }

    // player
    if (border_collision()) {
        player.health -= 1;
    }
    if (player != null) {
        player.move();
    }
    for (int i = collectables.size()-1; i >= 0; i--) {
        Collectable c = collectables.get(i);
        if (c instanceof EnemyBullet && check_collision(player, c)) {
            player.get_hit(c.damage);
            collectables.remove(i);
        }
        else if (c instanceof Powerup && check_collision(player, c)) {
            player.collect(c);
            collectables.remove(i);
        }
    }
}

void draw_scene() {
    fill(255);
    // draw entities
    ArrayList entities = new ArrayList();
    entities.addAll(bg_entities);
    entities.addAll(passives);
    entities.addAll(collectables);
    entities.addAll(enemies);
    if (player != null) entities.add(player);

    for (int i = 0; i < entities.size(); i++) {
        Entity e = entities.get(i);
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
            x = e.pos.x;
            y = e.pos.y;
            pushMatrix();
            translate(x, y);
            image(e.img, -e.img.width/2, -e.img.height/2);
            popMatrix();
            if (e instanceof Bubble)
                draw_text(e.txt, e.pos, e.txt_width, e.txt_height, 12);
        }
    }
    // draw health bar
    fill(127, 209, 59);
    if (player != null) rect(w/5, h-8, player.health*3, 3);
    fill(255);
}

void draw_text(String txt, PVector pos, int txt_width, int txt_height, int txt_size) {
    fill(0);
    textSize(txt_size);
    text(txt, pos.x-txt_width/2, pos.y-txt_height/2, txt_width, txt_height);
    fill(255);
}

boolean check_collision(Actor a, Collectable c) {
    int[] r1 = {a.pos.x-a.img.width/2, a.pos.y-a.img.height/2, a.img.width, a.img.height};
    int[] r2 = {c.pos.x-c.img.width/2, c.pos.y-c.img.height/2, c.img.width, c.img.height};
    if (r1[0] > r2[0] + r2[2] || r1[0] + r1[2] < r2[0] || r1[1] > r2[1] + r2[3] || r1[1] + r1[3] < r2[1]) {
        return false;
    }
    return true;
}

boolean border_collision() {
    return player.pos.y < 50 || player.y > 250;
}

/* --------------- populate --------------- */

/* level population */
void populate_stage() {
    if (debug) println("Stage: " + stage_index);

    switch (stage_index) {
        case 0:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 30*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 120));
            break;

        case 1:
            for (int i = 0; i < 24; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 80));
            break;

        case 2:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 30*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 150));
            enemies.add(new Boss(new PVector(w + 100, h/2), new PVector(-0.6, 1.5), "boss0", 50, 80, ""));
            break;

        case 3:
            for (int i = 0; i < 8; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 150));
            break;

        case 4:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 30*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 150));
            enemies.add(new Boss(new PVector(w + 100, h/2), new PVector(-0.6, 1.5), "boss0", 50, 80, "guns"));
            break;

        case 5: // yay new guns are fun :)
            for (int i = 0; i < 32; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 150));
            break;

        case 6:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 130));
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 100 + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 180));
            break;

        case 7:
            for (int i = 0; i < 24; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 150));
            break;

        case 8:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 150));
            enemies.add(new Boss(new PVector(w + 100, h/2-20), new PVector(-0.8, 1.5), "boss0", 150, 80, "health"));
            enemies.add(new Boss(new PVector(w + 100, h/2+20), new PVector(-0.6, 1.5), "boss0", 150, 80, ""));
            break;

        case 9:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy2", 40, 150));
            break;

        case 10:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 130));
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 100 + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy2", 40, 180));
            break;

        case 11:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy2", 40, 150));
            enemies.add(new Boss(new PVector(w + 100, h/2-20), new PVector(-0.8, 1.5), "boss0", 150, 80, "health"));
            enemies.add(new Boss(new PVector(w + 100, h/2+20), new PVector(-0.6, 1.5), "boss0", 150, 80, ""));
            break;

        case 12:
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy0", 10, 130));
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 94 + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy1", 20, 180));
            for (int i = 0; i < 16; i++) enemies.add(new Enemy(new PVector(w + 190 + 20*(i-i%8)/8, 100 + i%8*15), new PVector(-0.5, 1), "enemy2", 40, 230));
            enemies.add(new Boss(new PVector(w + 100, h/2+20), new PVector(-0.6, 1.5), "boss1", 300, 80, ""));
            break;
    }
}

void populate_initial() {
    // build player
    PVector speed = new PVector(0, 0);
    PVector pos = new PVector(w/2, h/2); // w/3
    player = new Player(pos, speed);

    // sparks
    for (int i = 0; i < 40; i++) {
        PVector speed = new PVector(-1, 0);
        PVector pos = new PVector(int(random(w)), int(random(h)));
        String name ="spark" + str(int(random(3)));
        Spark s = new Spark(pos, speed, name);
        bg_entities.add(s);
    }

    // upper border
    PVector pos = new PVector(0, 0);
    PVector speed = new PVector(-2, 0);
    PVector pos1 = new PVector(0, 0);
    PVector pos2 = new PVector(0, 30);
    for (int i = 0; i < 500; i++) {
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
    for (int i = 0; i < 500; i++) {
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

void add_bubble(String voice, String text) {
    passives.clear();
    Bubble b = new Bubble(voice, text);
    passives.add(b);
}

void load_images() {
    images = new HashMap();
    String[] image_strings = {"logo", "player", "enemy0", "bullet0", "enemy_bullet0",
    "spark0", "spark1", "spark2", "powerup_guns", "powerup_health",
    "explosion0", "explosion1", "explosion2", "explosion3",
    "bubble_narrator", "bubble_voice0", "bubble_voice1", "boss0", "enemy1",
    "boss1", "enemy2", "enemy_bullet1"};
    for (int i = 0; i < image_strings.length; i++) {
        String name = image_strings[i];
        if (debug) println("Preloading " + name + "...");
        PImage img = loadImage("img/" + name + ".png");
        images.put(name, img);
    }
    if (debug) println('Loaded ' + images.size() + ' images.');
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

void check_menu_keys() {
    if (key_space) {
        state = "story";
    }
}

boolean skip_story() {
    return key_space;
}
