BEGIN;

-- Insert missing profiles for any auth.users that don't have a public.users row
INSERT INTO public.users (id, name, email, avatar_url)
SELECT 
    au.id,
    COALESCE(
        NULLIF(TRIM(au.raw_user_meta_data ->> 'name'), ''),
        SPLIT_PART(COALESCE(au.email, ''), '@', 1),
        'User'
    ) AS name,
    COALESCE(au.email, '') AS email,
    NULLIF(TRIM(au.raw_user_meta_data ->> 'avatar_url'), '') AS avatar_url
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

COMMIT;
