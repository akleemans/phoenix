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
        img = images.get(name);
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
    int damage;

    Actor(PVector _pos, PVector _speed, String _type) {
        super(_pos, _speed);
        super.set_image(_type);
    }

    void get_hit(int damage) {
        health -= damage;
    }
}

class Player extends Actor {
    int armor;
    Player(PVector _pos, PVector _speed) {
        super(_pos, _speed, "player");
        health = 100;
        damage = 10;
    }

    void fire_bullet() {
        PVector speed = new PVector(5, 0);
        if (damage == 10) {
            collectables.add(new PlayerBullet(pos, speed, damage));
        }
        else if (damage >= 20) {
            collectables.add(new PlayerBullet(new PVector(pos.x, pos.y+5), speed, damage));
            collectables.add(new PlayerBullet(new PVector(pos.x, pos.y-5), speed, damage));
        }

        // better guns: faster?
    }

    void collect(Powerup p) {
        if (debug) println("Collected powerup: " + p.type);
        health += p.health;
        armor += p.armor;
        if (p.damage != 0) {
            damage += p.damage;
        }
    }
}

class Enemy extends Actor {
    PVector buffer;

    Enemy(PVector _pos, PVector _speed, String _type, int _health, int xbuffer) {
        super(_pos, _speed, _type);
        health = _health;
        damage = 10;
        buffer = new PVector(xbuffer, h/2);
    }

    void fire_bullet() {
        PVector speed = new PVector(-4, 0);
        EnemyBullet b = new EnemyBullet(pos, speed, damage);
        collectables.add(b);
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

        if (int(random(200)) == 17) // magic number 17
            fire_bullet();
    }
}

class Boss extends Enemy {
    String powerup;
    Boss(PVector _pos, PVector _speed, String _type, int _health, int xbuffer, String _powerup) {
        super(_pos, _speed, _type, _health, xbuffer);
        powerup = _powerup;
    }

    /* boss also moves sideways */
    void move() {
        if ((speed.x < 0 && buffer.x < 0) || (speed.x > 0 && buffer.x > 60)) speed.x *= -1;
        if (pos.x < w) buffer.x += speed.x;
        pos.x += speed.x;

        if (buffer.y > 180 || buffer.y < 120) speed.y *= -1;
        buffer.y += speed.y;
        pos.y += speed.y;

        if (int(random(50)) == 17) // magic number 17
            fire_bullet();
    }

}

/* Collectable entities */
class Collectable extends Entity {
    Collectable(PVector _pos, PVector _speed, String _type) {
        super(_pos, _speed);
        super.set_image(_type);
    }

    /* Moving */
    void move() {
        pos.x = pos.x + speed.x;
        pos.y = pos.y + speed.y;
    }
}

class PlayerBullet extends Collectable {
    int damage;
    PlayerBullet(PVector _pos, PVector _speed, int _damage) {
        super(_pos, _speed, "bullet0");
        damage = _damage;
    }
}

class EnemyBullet extends Collectable {
    int damage;
    EnemyBullet(PVector _pos, PVector _speed, int _damage) {
        super(_pos, _speed, "enemy_bullet0");
        damage = _damage;
    }
}

class Powerup extends Collectable {
    String type; // guns, armor, health
    int damage = 0;
    int armor = 0;
    int health = 0;
    Powerup(PVector _pos, String _type) {
        PVector speed = new PVector(-1.5, 0);
        super(_pos, speed, "powerup_" + _type);
        type = _type;
        if (type.equals("guns")) damage = 10;
        else if (type.equals("armor")) armor = 20;
        else if (type.equals("health")) health = 50;
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

class Explosion extends Entity {
    int last_sprite_change;
    int type;
    Explosion(PVector _pos) {
        PVector speed = new PVector(0, 0);
        super(_pos, speed);
        super.set_image("explosion0");
        type = 0;
        last_sprite_change = frameCount;
    }

    void move() {
        if (frameCount - last_sprite_change == 5) {
            last_sprite_change = frameCount;
            type += 1;
            super.set_image("explosion" + str(type));
        }
    }
}

class Bubble extends Entity {
    String txt;
    int txt_width, txt_height;
    Bubble(String _type, String _txt) {
        // TODO pos depends on type
        if (_type.equals("narrator")) int pos_x = w/2;
        else if (_type.equals("voice0")) int pos_x = w/3;
        else if (_type.equals("voice1")) int pos_x = 2*w/3;

        PVector pos = new PVector(pos_x, h/3);
        PVector speed = new PVector(0, 0);
        txt = _txt;
        txt_width = 104;
        txt_height = 60;
        super(pos, speed);
        super.set_image("bubble_" + _type);
    }
}
