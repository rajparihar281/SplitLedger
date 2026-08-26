BEGIN;

DROP POLICY IF EXISTS "Members can read their groups" ON public.groups;

CREATE POLICY "Members can read their groups" ON public.groups
FOR SELECT USING (
  public.is_group_member(id) OR auth.uid() = created_by
);

COMMIT;
