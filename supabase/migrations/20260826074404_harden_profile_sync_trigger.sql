-- Harden the trigger function
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;

-- Helper function to check group membership without recursion
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id AND user_id = auth.uid()
  );
$$;

-- Users policies
CREATE POLICY "Users can read their own profile" ON public.users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can read profiles of group members" ON public.users
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.group_members gm1
    JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid() AND gm2.user_id = public.users.id
  )
);

-- Groups policies
CREATE POLICY "Members can read their groups" ON public.groups
FOR SELECT USING (public.is_group_member(id));

CREATE POLICY "Users can create groups" ON public.groups
FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Owners can update their groups" ON public.groups
FOR UPDATE USING (auth.uid() = created_by);

-- Group Members policies
CREATE POLICY "Members can view group members" ON public.group_members
FOR SELECT USING (public.is_group_member(group_id));

CREATE POLICY "Owners can manage membership" ON public.group_members
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.groups g WHERE g.id = group_id AND g.created_by = auth.uid()
  )
);

-- Expenses policies
CREATE POLICY "Members can read expenses" ON public.expenses
FOR SELECT USING (public.is_group_member(group_id));

CREATE POLICY "Members can create expenses" ON public.expenses
FOR INSERT WITH CHECK (
  public.is_group_member(group_id) AND auth.uid() = created_by
);

CREATE POLICY "Creators and group owners can update expenses" ON public.expenses
FOR UPDATE USING (
  auth.uid() = created_by OR
  EXISTS (
    SELECT 1 FROM public.groups WHERE id = group_id AND created_by = auth.uid()
  )
);

CREATE POLICY "Creators and group owners can delete expenses" ON public.expenses
FOR DELETE USING (
  auth.uid() = created_by OR
  EXISTS (
    SELECT 1 FROM public.groups WHERE id = group_id AND created_by = auth.uid()
  )
);

-- Expense splits policies
CREATE POLICY "Members can access expense splits" ON public.expense_splits
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.is_group_member(e.group_id)
  )
);

CREATE POLICY "Members can insert expense splits" ON public.expense_splits
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.is_group_member(e.group_id)
  )
);

CREATE POLICY "Members can update expense splits" ON public.expense_splits
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.is_group_member(e.group_id)
  )
);

CREATE POLICY "Members can delete expense splits" ON public.expense_splits
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.is_group_member(e.group_id)
  )
);

-- Settlements policies
CREATE POLICY "Members can read settlements" ON public.settlements
FOR SELECT USING (public.is_group_member(group_id));

CREATE POLICY "Members can insert settlements" ON public.settlements
FOR INSERT WITH CHECK (public.is_group_member(group_id));
