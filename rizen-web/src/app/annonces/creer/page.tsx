import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";
import { CreateListingClient } from "./CreateListingClient";

export const dynamic = "force-dynamic";

export default async function CreateListingPage() {
  const cookieStore = await cookies();

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return cookieStore.getAll(); },
        setAll() {},
      },
    }
  );

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/auth/gate?redirect=/annonces/creer");

  // Profil utilisateur
  const { data: profil } = await supabase
    .from("profils")
    .select("prenom, photo")
    .eq("id", user.id)
    .maybeSingle();

  // Catégories
  const { data: categories } = await supabase
    .from("categories")
    .select("id, nom")
    .order("nom", { ascending: true });

  return (
    <CreateListingClient
      userId={user.id}
      prenom={profil?.prenom ?? null}
      photo={profil?.photo ?? null}
      categories={categories ?? []}
    />
  );
}
