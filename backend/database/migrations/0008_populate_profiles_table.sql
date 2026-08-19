-- Migration: Update trigger to populate both users and profiles tables
-- Also backfill existing users into profiles

-- Update trigger to insert into BOTH tables
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert into public.users
  INSERT INTO public.users (id, username)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data ->> 'username',
             'user_' || LEFT(new.id::text, 8))
  );

  -- Also insert into public.profiles for backward compatibility
  INSERT INTO public.profiles (id, username, created_at)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data ->> 'username',
             'user_' || LEFT(new.id::text, 8)),
    NOW()
  );

  RETURN new;
END;
$$;

-- Backfill existing users who are missing from profiles
INSERT INTO public.profiles (id, username, created_at)
SELECT id, username, created_at
FROM public.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
);

-- Verify results
SELECT
  (SELECT COUNT(*) FROM public.users) as users_count,
  (SELECT COUNT(*) FROM public.profiles) as profiles_count,
  CASE
    WHEN (SELECT COUNT(*) FROM public.users) = (SELECT COUNT(*) FROM public.profiles)
    THEN '✓ Tables in sync'
    ELSE '✗ Tables out of sync'
  END as sync_status;
