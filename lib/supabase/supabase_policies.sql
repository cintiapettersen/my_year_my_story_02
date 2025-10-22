-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE memory_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view all profiles" ON users
  FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profile" ON users
  FOR DELETE USING (auth.uid() = id);

-- Stories table policies
CREATE POLICY "Users can create their own stories" ON stories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view public stories and their own stories" ON stories
  FOR SELECT USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can update their own stories" ON stories
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stories" ON stories
  FOR DELETE USING (auth.uid() = user_id);

-- Memories table policies
CREATE POLICY "Users can create their own memories" ON memories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view memories of accessible stories" ON memories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM stories 
      WHERE stories.id = memories.story_id 
      AND (stories.is_public = true OR stories.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can update their own memories" ON memories
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own memories" ON memories
  FOR DELETE USING (auth.uid() = user_id);

-- Memory media table policies
CREATE POLICY "Users can create media for their own memories" ON memory_media
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view media of accessible memories" ON memory_media
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM memories m
      JOIN stories s ON s.id = m.story_id
      WHERE m.id = memory_media.memory_id
      AND (s.is_public = true OR s.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can update their own memory media" ON memory_media
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own memory media" ON memory_media
  FOR DELETE USING (auth.uid() = user_id);

-- Comments table policies
CREATE POLICY "Authenticated users can create comments on public stories" ON comments
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM stories 
      WHERE stories.id = comments.story_id 
      AND stories.is_public = true
    )
  );

CREATE POLICY "Users can view comments on accessible stories" ON comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM stories 
      WHERE stories.id = comments.story_id 
      AND (stories.is_public = true OR stories.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can update their own comments" ON comments
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);

-- Likes table policies
CREATE POLICY "Authenticated users can like public stories" ON likes
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM stories 
      WHERE stories.id = likes.story_id 
      AND stories.is_public = true
    )
  );

CREATE POLICY "Users can view likes on accessible stories" ON likes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM stories 
      WHERE stories.id = likes.story_id 
      AND (stories.is_public = true OR stories.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can delete their own likes" ON likes
  FOR DELETE USING (auth.uid() = user_id);

-- Follows table policies
CREATE POLICY "Authenticated users can follow others" ON follows
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = follower_id);

CREATE POLICY "Users can view all follow relationships" ON follows
  FOR SELECT USING (true);

CREATE POLICY "Users can delete their own follow relationships" ON follows
  FOR DELETE USING (auth.uid() = follower_id);