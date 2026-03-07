-- Ensure the UUID extension is active for generating IDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- SCENARIO STEPS TABLE ---

CREATE TABLE IF NOT EXISTS scenario_steps (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	description TEXT NOT NULL
);

TRUNCATE TABLE scenario_steps;

INSERT INTO scenario_steps (description) 
VALUES 
    ('drinks_offer'),
    ('water_type'),
    ('ice_question'),
    ('ready_to_order'),
    ('appetizers'),
    ('entrees'),
    ('steak_doneness'),
    ('side_choice'),
    ('is_that_all'),
    ('allergies');

-- SKILLS PRACTICED TABLE ---

CREATE TABLE IF NOT EXISTS skills_practiced (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	skill_name TEXT NOT NULL
);

TRUNCATE TABLE skills_practiced;

INSERT INTO skills_practiced (skill_name) 
VALUES 
    ('Small talk'),
    ('Ordering'),
    ('Notifying of allergies');

-- PROMPTS TABLE ---

CREATE TABLE IF NOT EXISTS prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Adding UNIQUE here enforces the One-to-One relationship
    scenario_step_id UUID UNIQUE REFERENCES scenario_steps(id) ON DELETE CASCADE,
    audio_url TEXT NOT NULL,
    image_speaking_url TEXT NOT NULL,
    image_listening_url TEXT NOT NULL,
    image_confused_url TEXT NOT NULL,
    skill_practiced_id UUID REFERENCES skills_practiced(id) ON DELETE CASCADE,
    prompt_text TEXT NOT NULL
);

TRUNCATE TABLE prompts;

INSERT INTO prompts (
    scenario_step_id, 
    audio_url, 
    image_speaking_url, 
    image_listening_url, 
    image_confused_url,
    skill_practiced_id,
    prompt_text
) 
VALUES 
    (
        (SELECT id FROM scenario_steps WHERE description = 'drinks_offer' LIMIT 1),
        'drinks_offer.mp3',
        'intro_hello.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Here''s the menu. Can I get you started with any drinks?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'water_type' LIMIT 1),
        'water_type.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Still or sparkling?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'ice_question' LIMIT 1),
        'ice_question.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Would you like ice with it?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'ready_to_order' LIMIT 1),
        'ready_to_order.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Are you ready to order?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'appetizers' LIMIT 1),
        'appetizers.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Any appetizers to get you started?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'entrees' LIMIT 1),
        'entrees.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Would you like to order any entrees?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'steak_doneness' LIMIT 1),
        'steak_doneness.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'How would you like your steak?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'side_choice' LIMIT 1),
        'side_choice.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Would you like salad or fries as your side?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'is_that_all' LIMIT 1),
        'is_that_all.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Is that all for you?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'allergies' LIMIT 1),
        'allergies.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Notifying of allergies' LIMIT 1),
        'Do you have any allergies?'
    );