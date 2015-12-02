String state = "story"; // menu, story, game, info
int h = 400;
int w = 600;
ArrayList story;
int story_index = 0;

/* Setting up canvas and populating boids. */
void setup() {
    // load story
    load_story();

    // load images

    smooth();
    size(w, h);
    frameRate(1);
}

/* Main loop. */
void draw() {
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
        // game
    }
}

void load_story() {
    String[] lines = loadStrings("story.dat");
    story = new ArrayList();
    for (int i = 1; i < lines.length; i++) {
        String[] parts = split(lines[i], "|");
        story.add(parts);
    }
}
