-- Ensure the UUID extension is active for generating IDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Delete existing tables
DROP TABLE IF EXISTS prompts CASCADE;
DROP TABLE IF EXISTS skills_practiced CASCADE;
DROP TABLE IF EXISTS scenario_steps CASCADE;

-- SCENARIO STEPS TABLE ---

CREATE TABLE IF NOT EXISTS scenario_steps (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	description TEXT NOT NULL
);

INSERT INTO scenario_steps (description) 
VALUES 
    ('reservation'),
    ('reservation_name'),
    ('number_people'),
    ('drinks_offer'),
    ('water_type'),
    ('ice_question'),
    ('ready_to_order'),
    ('appetizers'),
    ('entrees'),
    ('steak_doneness'),
    ('side_choice'),
    ('is_that_all'),
    ('be_back_shortly'),
    ('how_help'),
    ('check_order'),
    ('here_bruschetta'),
    ('here_soup'),
    ('here_pasta'),
    ('here_chicken'),
    ('here_steak'),
    ('wrong_order_apology'),
    ('wrong_order_resolved_pasta'),
    ('wrong_order_resolved_chicken'),
    ('wrong_order_resolved_steak'),
    ('wrong_order_nudge'),
    ('how_is_everything'),
    ('are_you_done'),
    ('ready_for_bill'),
    ('check_receipt'),
    ('resolve_receipt'),
    ('payment_method'),
    ('receipt');

-- SKILLS PRACTICED TABLE ---

CREATE TABLE IF NOT EXISTS skills_practiced (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	skill_name TEXT NOT NULL
);

INSERT INTO skills_practiced (skill_name) 
VALUES 
    ('Getting seated'),
    ('Small talk'),
    ('Ordering'),
    ('Paying');

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
        (SELECT id FROM scenario_steps WHERE description = 'reservation' LIMIT 1),
        'reservation.mp3',
        'intro_hello.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Getting seated' LIMIT 1),
        'Welcome to Bob''s Eatery. Do you have a reservation?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'reservation_name' LIMIT 1),
        'reservation_name.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Getting seated' LIMIT 1),
        'Can I have the name that''s on the reservation?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'number_people' LIMIT 1),
        'number_people.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Getting seated' LIMIT 1),
        'How many people are in your party?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'drinks_offer' LIMIT 1),
        'drinks_offer.mp3',
        'intro_talk.png',
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
        (SELECT id FROM scenario_steps WHERE description = 'be_back_shortly' LIMIT 1),
        'be_back_shortly.mp3',
        'order_talk.png',
        'order_listen.png',
        'order_talk.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Ordering' LIMIT 1),
        'Great, I''ll be back shortly with your food once it''s ready.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'here_bruschetta' LIMIT 1),
        'here_bruschetta.mp3',
        'here_bruschetta.png',
        'here_bruschetta.png',
        'here_bruschetta.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Here''s your bruschetta to get you started! I''ll be back shortly with your entree.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'here_soup' LIMIT 1),
        'here_soup.mp3',
        'here_soup.png',
        'here_soup.png',
        'here_soup.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Here''s the soup of the day to get you started! I''ll be back shortly with your entree.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'here_pasta' LIMIT 1),
        'here_pasta.mp3',
        'here_pasta.png',
        'here_pasta.png',
        'here_pasta.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Alright and here''s the seafood alfredo. Let me know if you need anything else.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'here_chicken' LIMIT 1),
        'here_chicken.mp3',
        'here_chicken.png',
        'here_chicken.png',
        'here_chicken.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Alright and here''s the chicken katsu. Let me know if you need anything else.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'here_steak' LIMIT 1),
        'here_steak.mp3',
        'here_steak.png',
        'here_steak.png',
        'here_steak.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Alright and here''s the steak. Let me know if you need anything else.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'wrong_order_apology' LIMIT 1),
        'wrong_order_apology.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'I''m so sorry about that - let me go back and get your order.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'wrong_order_resolved_pasta' LIMIT 1),
        'wrong_order_resolved.mp3',
        'here_pasta.png',
        'here_pasta.png',
        'here_pasta.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Here is your actual order, enjoy!'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'wrong_order_resolved_chicken' LIMIT 1),
        'wrong_order_resolved.mp3',
        'here_chicken.png',
        'here_chicken.png',
        'here_chicken.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Here is your actual order, enjoy!'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'wrong_order_resolved_steak' LIMIT 1),
        'wrong_order_resolved.mp3',
        'here_steak.png',
        'here_steak.png',
        'here_steak.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Here is your actual order, enjoy!'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'how_help' LIMIT 1),
        'how_help.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Hi! How can I help you?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'check_order' LIMIT 1),
        'check_order.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'So sorry about the wait - let me check on your order for you'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'wrong_order_nudge' LIMIT 1),
        'wrong_order_nudge.mp3',
        'intro_confused.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Wait a second, let me look at my notepad... did I bring you the right dish?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'how_is_everything' LIMIT 1),
        'how_is_everything.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'How is everything?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'are_you_done' LIMIT 1),
        'are_you_done.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Small talk' LIMIT 1),
        'Are you done with your food?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'ready_for_bill' LIMIT 1),
        'ready_for_bill.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Paying' LIMIT 1),
        'Are you ready for the bill?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'check_receipt' LIMIT 1),
        'check_receipt.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Paying' LIMIT 1),
        'Here''s the receipt - please check it over'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'resolve_receipt' LIMIT 1),
        'resolve_receipt.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Paying' LIMIT 1),
        'I''m so sorry about that - lets see...here''s your actual receipt.'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'payment_method' LIMIT 1),
        'payment_method.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Paying' LIMIT 1),
        'How would you like to pay?'
    ),
    (
        (SELECT id FROM scenario_steps WHERE description = 'receipt' LIMIT 1),
        'receipt.mp3',
        'intro_talk.png',
        'intro_listen.png',
        'intro_confused.png',
        (SELECT id FROM skills_practiced WHERE skill_name = 'Paying' LIMIT 1),
        'Would you like your receipt?'
    );