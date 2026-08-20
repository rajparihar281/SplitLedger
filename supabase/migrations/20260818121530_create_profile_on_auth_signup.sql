-- Create an application profile automatically whenever a Supabase Auth user
-- is created.
--
-- Identity invariant:
--   auth.users.id = public.users.id
--
-- The Auth UUID is authoritative. The application profile cannot choose
-- a different identity UUID.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.users (
        id,
        name,
        email,
        avatar_url
    )
    values (
        new.id,
        coalesce(
            nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
            split_part(coalesce(new.email, ''), '@', 1),
            'User'
        ),
        coalesce(new.email, ''),
        nullif(
            trim(new.raw_user_meta_data ->> 'avatar_url'),
            ''
        )
    );

    return new;
end;
$$;


-- Run the profile synchronization function whenever a new Auth identity
-- is created.

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();