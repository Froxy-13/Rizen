import { createBrowserClient } from "@supabase/ssr";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Client Supabase côté navigateur — synchronise la session dans les cookies
// pour que le middleware puisse lire la session sans passer par localStorage.
export const supabase = createBrowserClient(supabaseUrl, supabaseAnonKey);

// Helper : utilisateur connecté
export async function getUser() {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user;
}

// Helper : profil complet depuis la table profils
export async function getProfil(userId: string) {
  const { data } = await supabase
    .from("profils")
    .select("*")
    .eq("id", userId)
    .maybeSingle();
  return data;
}
