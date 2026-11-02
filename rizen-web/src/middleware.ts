import { createServerClient } from "@supabase/ssr";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const response = NextResponse.next({
    request: { headers: request.headers },
  });

  // Client Supabase qui lit/écrit les cookies de session
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  // Récupère la session (rafraîchit le token si besoin)
  const { data: { user } } = await supabase.auth.getUser();

  // ── Protection routes /admin/* ─────────────────────────────────────
  if (pathname.startsWith("/admin")) {
    // La page de login admin est toujours accessible
    if (pathname === "/admin/login") {
      // Si déjà connecté en superadmin → dashboard directement
      if (user) {
        const { data: profil } = await supabase
          .from("profils")
          .select("role")
          .eq("id", user.id)
          .maybeSingle();
        if (profil?.role === "superadmin") {
          return NextResponse.redirect(new URL("/admin/dashboard", request.url));
        }
      }
      return response;
    }

    // Toutes les autres routes /admin/* nécessitent superadmin
    if (!user) {
      return NextResponse.redirect(new URL("/admin/login", request.url));
    }

    const { data: profil } = await supabase
      .from("profils")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profil?.role !== "superadmin") {
      await supabase.auth.signOut();
      return NextResponse.redirect(new URL("/admin/login", request.url));
    }

    return response;
  }

  // ── Redirection si déjà connecté sur /auth/* ──────────────────────
  if (pathname.startsWith("/auth/")) {
    if (user) {
      return NextResponse.redirect(new URL("/", request.url));
    }
    return response;
  }

  return response;
}

export const config = {
  matcher: [
    // Protège toutes les routes /admin et /auth
    "/admin/:path*",
    "/auth/:path*",
  ],
};
