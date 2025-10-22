CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;


-- Sample Data for Supabase Project

-- Insert users into auth.users first
INSERT INTO auth.users (id, email, password)
VALUES
    (insert_user_to_auth('alice@example.com', 'password123'), 'alice@example.com', 'password123'),
    (insert_user_to_auth('bob@example.com', 'password123'), 'bob@example.com', 'password123'),
    (insert_user_to_auth('charlie@example.com', 'password123'), 'charlie@example.com', 'password123');

-- Insert user profiles
INSERT INTO public.users (id, email, full_name, avatar_url)
VALUES
    ((SELECT id FROM auth.users WHERE email = 'alice@example.com'), 'alice@example.com', 'Alice Smith', 'https://example.com/avatars/alice.jpg'),
    ((SELECT id FROM auth.users WHERE email = 'bob@example.com'), 'bob@example.com', 'Bob Johnson', 'https://example.com/avatars/bob.jpg'),
    ((SELECT id FROM auth.users WHERE email = 'charlie@example.com'), 'charlie@example.com', 'Charlie Brown', 'https://example.com/avatars/charlie.jpg');

-- Insert stories
INSERT INTO public.stories (user_id, year, title, content, cover_image_url, is_public)
VALUES
    ((SELECT id FROM public.users WHERE email = 'alice@example.com'), 2023, 'Alice''s Adventures in 2023', 'A year full of exciting new experiences and growth.', 'https://example.com/covers/alice2023.jpg', TRUE),
    ((SELECT id FROM public.users WHERE email = 'alice@example.com'), 2022, 'Alice''s Reflective Year 2022', 'Looking back at a quieter but meaningful year.', NULL, FALSE),
    ((SELECT id FROM public.users WHERE email = 'bob@example.com'), 2023, 'Bob''s Big Year 2023', 'From coding to hiking, a truly memorable year.', 'https://example.com/covers/bob2023.jpg', TRUE),
    ((SELECT id FROM public.users WHERE email = 'charlie@example.com'), 2023, 'Charlie''s Creative Journey 2023', 'Exploring new artistic endeavors and projects.', NULL, TRUE);

-- Insert memories
INSERT INTO public.memories (story_id, user_id, title, description, memory_date, location, tags)
VALUES
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'Mountain Hike', 'Reached the summit after a challenging climb.', '2023-07-15', 'Rocky Mountains', ARRAY['adventure', 'nature', 'hiking']),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'New Job Start', 'First day at the new company, very exciting!', '2023-01-09', 'New York City', ARRAY['career', 'milestone']),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'bob@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'bob@example.com'),
     'First Marathon', 'Completed my first full marathon!', '2023-04-22', 'Boston', ARRAY['sport', 'achievement', 'running']),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'bob@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'bob@example.com'),
     'Family Vacation', 'Relaxing time with family by the beach.', '2023-08-01', 'Maui, Hawaii', ARRAY['travel', 'family', 'beach']),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'charlie@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'charlie@example.com'),
     'Art Exhibition', 'Showcased my paintings at the local gallery.', '2023-11-10', 'Local Gallery', ARRAY['art', 'exhibition', 'creativity']);

-- Insert memory media
INSERT INTO public.memory_media (memory_id, user_id, media_url, media_type, caption, display_order)
VALUES
    ((SELECT id FROM public.memories WHERE title = 'Mountain Hike' AND user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com')),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'https://example.com/media/mountain_hike_1.jpg', 'image', 'View from the top!', 1),
    ((SELECT id FROM public.memories WHERE title = 'Mountain Hike' AND user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com')),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'https://example.com/media/mountain_hike_2.mp4', 'video', 'Short clip of the trail.', 2),
    ((SELECT id FROM public.memories WHERE title = 'First Marathon' AND user_id = (SELECT id FROM public.users WHERE email = 'bob@example.com')),
     (SELECT id FROM public.users WHERE email = 'bob@example.com'),
     'https://example.com/media/marathon_finish.jpg', 'image', 'Crossing the finish line!', 1),
    ((SELECT id FROM public.memories WHERE title = 'Art Exhibition' AND user_id = (SELECT id FROM public.users WHERE email = 'charlie@example.com')),
     (SELECT id FROM public.users WHERE email = 'charlie@example.com'),
     'https://example.com/media/art_exhibition_painting.jpg', 'image', 'My favorite piece from the show.', 1);

-- Insert comments
INSERT INTO public.comments (story_id, user_id, content)
VALUES
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'bob@example.com'),
     'Amazing year, Alice! Love the mountain hike.'),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'bob@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'Congrats on the marathon, Bob! So inspiring.'),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'charlie@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'alice@example.com'),
     'Your art is beautiful, Charlie!');

-- Insert likes
INSERT INTO public.likes (story_id, user_id)
VALUES
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'bob@example.com')),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'alice@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'charlie@example.com')),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'bob@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'alice@example.com')),
    ((SELECT id FROM public.stories WHERE user_id = (SELECT id FROM public.users WHERE email = 'charlie@example.com') AND year = 2023),
     (SELECT id FROM public.users WHERE email = 'bob@example.com'));

-- Insert follows
INSERT INTO public.follows (follower_id, following_id)
VALUES
    ((SELECT id FROM public.users WHERE email = 'alice@example.com'), (SELECT id FROM public.users WHERE email = 'bob@example.com')),
    ((SELECT id FROM public.users WHERE email = 'bob@example.com'), (SELECT id FROM public.users WHERE email = 'alice@example.com')),
    ((SELECT id FROM public.users WHERE email = 'alice@example.com'), (SELECT id FROM public.users WHERE email = 'charlie@example.com'));